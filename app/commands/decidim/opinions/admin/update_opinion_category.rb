# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      #  A command with all the business logic when an admin batch updates opinions category.
      class UpdateOpinionCategory < Rectify::Command
        # Public: Initializes the command.
        #
        # category_id - the category id to update
        # opinion_ids - the opinions ids to update.
        def initialize(category_id, opinion_ids)
          @category = Decidim::Category.find_by id: category_id
          @opinion_ids = opinion_ids
          @response = { category_name: "", successful: [], errored: [] }
        end

        # Executes the command. Broadcasts these events:
        #
        # - :update_opinions_category - when everything is ok, returns @response.
        # - :invalid_category - if the category is blank.
        # - :invalid_opinion_ids - if the opinion_ids is blank.
        #
        # Returns @response hash:
        #
        # - :category_name - the translated_name of the category assigned
        # - :successful - Array of names of the updated opinions
        # - :errored - Array of names of the opinions not updated because they already had the category assigned
        def call
          return broadcast(:invalid_category) if @category.blank?
          return broadcast(:invalid_opinion_ids) if @opinion_ids.blank?

          @response[:category_name] = @category.translated_name
          Opinion.where(id: @opinion_ids).find_each do |opinion|
            if @category == opinion.category
              @response[:errored] << opinion.title
            else
              transaction do
                update_opinion_category opinion
                notify_author opinion if opinion.coauthorships.any?
              end
              @response[:successful] << opinion.title
            end
          end

          broadcast(:update_opinions_category, @response)
        end

        private

        def update_opinion_category(opinion)
          opinion.update!(
            category: @category
          )
        end

        def notify_author(opinion)
          Decidim::EventsManager.publish(
            event: "decidim.events.opinions.opinion_update_category",
            event_class: Decidim::Opinions::Admin::UpdateOpinionCategoryEvent,
            resource: opinion,
            affected_users: opinion.notifiable_identities
          )
        end
      end
    end
  end
end
