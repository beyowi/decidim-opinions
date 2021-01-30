# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # This controller allows admins to manage opinions in a participatory process.
      class OpinionsController < Admin::ApplicationController
        include Decidim::ApplicationHelper
        include Decidim::Opinions::Admin::Filterable

        helper Opinions::ApplicationHelper
        helper Decidim::Opinions::Admin::OpinionRankingsHelper
        helper Decidim::Messaging::ConversationHelper
        helper_method :opinions, :query, :form_presenter, :opinion, :opinion_ids
        helper Opinions::Admin::OpinionBulkActionsHelper

        def show
          @notes_form = form(OpinionNoteForm).instance
          @answer_form = form(Admin::OpinionAnswerForm).from_model(opinion)
        end

        def new
          enforce_permission_to :create, :opinion
          @form = form(Admin::OpinionForm).from_params(
            attachment: form(AttachmentForm).from_params({})
          )
        end

        def create
          enforce_permission_to :create, :opinion
          @form = form(Admin::OpinionForm).from_params(params)

          Admin::CreateOpinion.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("opinions.create.success", scope: "decidim.opinions.admin")
              redirect_to opinions_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("opinions.create.invalid", scope: "decidim.opinions.admin")
              render action: "new"
            end
          end
        end

        def update_category
          enforce_permission_to :update, :opinion_category

          Admin::UpdateOpinionCategory.call(params[:category][:id], opinion_ids) do
            on(:invalid_category) do
              flash.now[:error] = I18n.t(
                "opinions.update_category.select_a_category",
                scope: "decidim.opinions.admin"
              )
            end

            on(:invalid_opinion_ids) do
              flash.now[:alert] = I18n.t(
                "opinions.update_category.select_a_opinion",
                scope: "decidim.opinions.admin"
              )
            end

            on(:update_opinions_category) do
              flash.now[:notice] = update_opinions_bulk_response_successful(@response, :category)
              flash.now[:alert] = update_opinions_bulk_response_errored(@response, :category)
            end
            respond_to do |format|
              format.js
            end
          end
        end

        def publish_answers
          enforce_permission_to :publish_answers, :opinions

          Decidim::Opinions::Admin::PublishAnswers.call(current_component, current_user, opinion_ids) do
            on(:invalid) do
              flash.now[:alert] = t(
                "opinions.publish_answers.select_a_opinion",
                scope: "decidim.opinions.admin"
              )
            end

            on(:ok) do
              flash.now[:notice] = I18n.t("opinions.publish_answers.success", scope: "decidim")
            end
          end

          respond_to do |format|
            format.js
          end
        end

        def update_scope
          enforce_permission_to :update, :opinion_scope

          Admin::UpdateOpinionScope.call(params[:scope_id], opinion_ids) do
            on(:invalid_scope) do
              flash.now[:error] = t(
                "opinions.update_scope.select_a_scope",
                scope: "decidim.opinions.admin"
              )
            end

            on(:invalid_opinion_ids) do
              flash.now[:alert] = t(
                "opinions.update_scope.select_a_opinion",
                scope: "decidim.opinions.admin"
              )
            end

            on(:update_opinions_scope) do
              flash.now[:notice] = update_opinions_bulk_response_successful(@response, :scope)
              flash.now[:alert] = update_opinions_bulk_response_errored(@response, :scope)
            end

            respond_to do |format|
              format.js
            end
          end
        end

        def edit
          enforce_permission_to :edit, :opinion, opinion: opinion
          @form = form(Admin::OpinionForm).from_model(opinion)
          @form.attachment = form(AttachmentForm).from_params({})
        end

        def update
          enforce_permission_to :edit, :opinion, opinion: opinion

          @form = form(Admin::OpinionForm).from_params(params)
          Admin::UpdateOpinion.call(@form, @opinion) do
            on(:ok) do |_opinion|
              flash[:notice] = t("opinions.update.success", scope: "decidim")
              redirect_to opinions_path
            end

            on(:invalid) do
              flash.now[:alert] = t("opinions.update.error", scope: "decidim")
              render :edit
            end
          end
        end

        private

        def collection
          @collection ||= Opinion.where(component: current_component).published
        end

        def opinions
          @opinions ||= filtered_collection
        end

        def opinion
          @opinion ||= collection.find(params[:id])
        end

        def opinion_ids
          @opinion_ids ||= params[:opinion_ids]
        end

        def update_opinions_bulk_response_successful(response, subject)
          return if response[:successful].blank?

          if subject == :category
            t(
              "opinions.update_category.success",
              subject_name: response[:subject_name],
              opinions: response[:successful].to_sentence,
              scope: "decidim.opinions.admin"
            )
          elsif subject == :scope
            t(
              "opinions.update_scope.success",
              subject_name: response[:subject_name],
              opinions: response[:successful].to_sentence,
              scope: "decidim.opinions.admin"
            )
          end
        end

        def update_opinions_bulk_response_errored(response, subject)
          return if response[:errored].blank?

          if subject == :category
            t(
              "opinions.update_category.invalid",
              subject_name: response[:subject_name],
              opinions: response[:errored].to_sentence,
              scope: "decidim.opinions.admin"
            )
          elsif subject == :scope
            t(
              "opinions.update_scope.invalid",
              subject_name: response[:subject_name],
              opinions: response[:errored].to_sentence,
              scope: "decidim.opinions.admin"
            )
          end
        end

        def form_presenter
          @form_presenter ||= present(@form, presenter_class: Decidim::Opinions::OpinionPresenter)
        end
      end
    end
  end
end
