# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A command with all the business logic when an admin merges opinions from
      # one component to another.
      class MergeOpinions < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless form.valid?

          broadcast(:ok, merge_opinions)
        end

        private

        attr_reader :form

        def merge_opinions
          transaction do
            merged_opinion = create_new_opinion
            merged_opinion.link_resources(opinions_to_link, "copied_from_component")
            form.opinions.each(&:destroy!) if form.same_component?
            merged_opinion
          end
        end

        def opinions_to_link
          return previous_links if form.same_component?

          form.opinions
        end

        def previous_links
          @previous_links ||= form.opinions.flat_map do |opinion|
            opinion.linked_resources(:opinions, "copied_from_component")
          end
        end

        def create_new_opinion
          original_opinion = form.opinions.first

          Decidim::Opinions::OpinionBuilder.copy(
            original_opinion,
            author: form.current_organization,
            action_user: form.current_user,
            extra_attributes: {
              component: form.target_component
            },
            skip_link: true
          )
        end
      end
    end
  end
end
