# frozen_string_literal: true

require "kaminari"
require "social-share-button"
require "ransack"
require "cells/rails"
require "cells-erb"
require "cell/partial"

module Decidim
  module Opinions
    # This is the engine that runs on the public interface of `decidim-opinions`.
    # It mostly handles rendering the created page associated to a participatory
    # process.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Opinions

      routes do
        resources :opinions, except: [:destroy] do
          member do
            get :compare
            get :complete
            get :edit_draft
            patch :update_draft
            get :preview
            post :publish
            delete :destroy_draft
            put :withdraw
          end
          resource :opinion_vote, only: [:create, :destroy]
          resource :opinion_widget, only: :show, path: "embed"
          resources :versions, only: [:show, :index]
        end
        resources :collaborative_drafts, except: [:destroy] do
          get :compare, on: :collection
          get :complete, on: :collection
          member do
            post :request_access, controller: "collaborative_draft_collaborator_requests"
            post :request_accept, controller: "collaborative_draft_collaborator_requests"
            post :request_reject, controller: "collaborative_draft_collaborator_requests"
            post :withdraw
            post :publish
          end
          resources :versions, only: [:show, :index]
        end
        root to: "opinions#index"
      end

      initializer "decidim_opinions.assets" do |app|
        app.config.assets.precompile += %w(decidim_opinions_manifest.js)
      end

      initializer "decidim.content_processors" do |_app|
        Decidim.configure do |config|
          config.content_processors += [:opinion]
        end
      end

      initializer "decidim_opinions.view_hooks" do
        Decidim.view_hooks.register(:participatory_space_highlighted_elements, priority: Decidim::ViewHooks::MEDIUM_PRIORITY) do |view_context|
          view_context.cell("decidim/opinions/highlighted_opinions", view_context.current_participatory_space)
        end

        if defined? Decidim::ParticipatoryProcesses
          Decidim::ParticipatoryProcesses.view_hooks.register(:process_group_highlighted_elements, priority: Decidim::ViewHooks::MEDIUM_PRIORITY) do |view_context|
            published_components = Decidim::Component.where(participatory_space: view_context.participatory_processes).published
            opinions = Decidim::Opinions::Opinion.published.not_hidden.except_withdrawn
                                                    .where(component: published_components)
                                                    .order_randomly(rand * 2 - 1)
                                                    .limit(Decidim::Opinions.config.process_group_highlighted_opinions_limit)

            next unless opinions.any?

            view_context.extend Decidim::ResourceReferenceHelper
            view_context.extend Decidim::Opinions::ApplicationHelper
            view_context.render(
              partial: "decidim/participatory_processes/participatory_process_groups/highlighted_opinions",
              locals: {
                opinions: opinions
              }
            )
          end
        end
      end

      initializer "decidim_changes" do
        Decidim::SettingsChange.subscribe "surveys" do |changes|
          Decidim::Opinions::SettingsChangeJob.perform_later(
            changes[:component_id],
            changes[:previous_settings],
            changes[:current_settings]
          )
        end
      end

      initializer "decidim_opinions.mentions_listener" do
        Decidim::Comments::CommentCreation.subscribe do |data|
          opinions = data.dig(:metadatas, :opinion).try(:linked_opinions)
          Decidim::Opinions::NotifyOpinionsMentionedJob.perform_later(data[:comment_id], opinions) if opinions
        end
      end

      # Subscribes to ActiveSupport::Notifications that may affect a Opinion.
      initializer "decidim_opinions.subscribe_to_events" do
        # when a opinion is linked from a result
        event_name = "decidim.resourceable.included_opinions.created"
        ActiveSupport::Notifications.subscribe event_name do |_name, _started, _finished, _unique_id, data|
          payload = data[:this]
          if payload[:from_type] == Decidim::Accountability::Result.name && payload[:to_type] == Opinion.name
            opinion = Opinion.find(payload[:to_id])
            opinion.update(state: "accepted", state_published_at: Time.current)
          end
        end
      end

      initializer "decidim_opinions.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Opinions::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Opinions::Engine.root}/app/views") # for opinion partials
      end

      initializer "decidim_opinions.add_badges" do
        Decidim::Gamification.register_badge(:opinions) do |badge|
          badge.levels = [1, 5, 10, 30, 60]

          badge.valid_for = [:user, :user_group]

          badge.reset = lambda { |model|
            if model.is_a?(User)
              Decidim::Coauthorship.where(
                coauthorable_type: "Decidim::Opinions::Opinion",
                author: model,
                user_group: nil
              ).count
            elsif model.is_a?(UserGroup)
              Decidim::Coauthorship.where(
                coauthorable_type: "Decidim::Opinions::Opinion",
                user_group: model
              ).count
            end
          }
        end

        Decidim::Gamification.register_badge(:accepted_opinions) do |badge|
          badge.levels = [1, 5, 15, 30, 50]

          badge.valid_for = [:user, :user_group]

          badge.reset = lambda { |model|
            opinion_ids = if model.is_a?(User)
                             Decidim::Coauthorship.where(
                               coauthorable_type: "Decidim::Opinions::Opinion",
                               author: model,
                               user_group: nil
                             ).select(:coauthorable_id)
                           elsif model.is_a?(UserGroup)
                             Decidim::Coauthorship.where(
                               coauthorable_type: "Decidim::Opinions::Opinion",
                               user_group: model
                             ).select(:coauthorable_id)
                           end

            Decidim::Opinions::Opinion.where(id: opinion_ids).accepted.count
          }
        end

        Decidim::Gamification.register_badge(:opinion_votes) do |badge|
          badge.levels = [5, 15, 50, 100, 500]

          badge.reset = lambda { |user|
            Decidim::Opinions::OpinionVote.where(author: user).select(:decidim_opinion_id).distinct.count
          }
        end
      end

      initializer "decidim_opinions.register_metrics" do
        Decidim.metrics_registry.register(:opinions) do |metric_registry|
          metric_registry.manager_class = "Decidim::Opinions::Metrics::OpinionsMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: true
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 2
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_registry.register(:accepted_opinions) do |metric_registry|
          metric_registry.manager_class = "Decidim::Opinions::Metrics::AcceptedOpinionsMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: false
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 3
            settings.attribute :stat_block, type: :string, default: "small"
          end
        end

        Decidim.metrics_registry.register(:opinion_votes) do |metric_registry|
          metric_registry.manager_class = "Decidim::Opinions::Metrics::VotesMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: true
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 3
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_registry.register(:opinion_endorsements) do |metric_registry|
          metric_registry.manager_class = "Decidim::Opinions::Metrics::EndorsementsMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: false
            settings.attribute :scopes, type: :array, default: %w(participatory_process)
            settings.attribute :weight, type: :integer, default: 4
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_operation.register(:participants, :opinions) do |metric_operation|
          metric_operation.manager_class = "Decidim::Opinions::Metrics::OpinionParticipantsMetricMeasure"
        end
        Decidim.metrics_operation.register(:followers, :opinions) do |metric_operation|
          metric_operation.manager_class = "Decidim::Opinions::Metrics::OpinionFollowersMetricMeasure"
        end
      end
    end
  end
end
