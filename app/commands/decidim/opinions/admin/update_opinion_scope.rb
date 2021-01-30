# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      #  A command with all the business logic when an admin batch updates opinions scope.
      class UpdateOpinionScope < Rectify::Command
        include TranslatableAttributes
        # Public: Initializes the command.
        #
        # scope_id - the scope id to update
        # opinion_ids - the opinions ids to update.
        def initialize(scope_id, opinion_ids)
          @scope = Decidim::Scope.find_by id: scope_id
          @opinion_ids = opinion_ids
          @response = { scope_name: "", successful: [], errored: [] }
        end

        # Executes the command. Broadcasts these events:
        #
        # - :update_opinions_scope - when everything is ok, returns @response.
        # - :invalid_scope - if the scope is blank.
        # - :invalid_opinion_ids - if the opinion_ids is blank.
        #
        # Returns @response hash:
        #
        # - :scope_name - the translated_name of the scope assigned
        # - :successful - Array of names of the updated opinions
        # - :errored - Array of names of the opinions not updated because they already had the scope assigned
        def call
          return broadcast(:invalid_scope) if @scope.blank?
          return broadcast(:invalid_opinion_ids) if @opinion_ids.blank?

          update_opinions_scope

          broadcast(:update_opinions_scope, @response)
        end

        private

        attr_reader :scope, :opinion_ids

        def update_opinions_scope
          @response[:scope_name] = translated_attribute(scope.name, scope.organization)
          Opinion.where(id: opinion_ids).find_each do |opinion|
            if scope == opinion.scope
              @response[:errored] << opinion.title
            else
              transaction do
                update_opinion_scope opinion
                notify_author opinion if opinion.coauthorships.any?
              end
              @response[:successful] << opinion.title
            end
          end
        end

        def update_opinion_scope(opinion)
          opinion.update!(
            scope: scope
          )
        end

        def notify_author(opinion)
          Decidim::EventsManager.publish(
            event: "decidim.events.opinions.opinion_update_scope",
            event_class: Decidim::Opinions::Admin::UpdateOpinionScopeEvent,
            resource: opinion,
            affected_users: opinion.notifiable_identities
          )
        end
      end
    end
  end
end
