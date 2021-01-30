# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A command with all the business logic when an admin splits opinions from
      # one component to another.
      class SplitOpinions < Rectify::Command
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

          broadcast(:ok, split_opinions)
        end

        private

        attr_reader :form

        def split_opinions
          transaction do
            form.opinions.flat_map do |original_opinion|
              # If copying to the same component we only need one copy
              # but linking to the original opinion links, not the
              # original opinion.
              create_opinion(original_opinion)
              create_opinion(original_opinion) unless form.same_component?
            end
          end
        end

        def create_opinion(original_opinion)
          split_opinion = Decidim::Opinions::OpinionBuilder.copy(
            original_opinion,
            author: form.current_organization,
            action_user: form.current_user,
            extra_attributes: {
              component: form.target_component
            },
            skip_link: true
          )

          opinions_to_link = links_for(original_opinion)
          split_opinion.link_resources(opinions_to_link, "copied_from_component")
        end

        def links_for(opinion)
          return opinion unless form.same_component?

          opinion.linked_resources(:opinions, "copied_from_component")
        end
      end
    end
  end
end
