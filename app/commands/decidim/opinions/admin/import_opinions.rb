# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A command with all the business logic when an admin imports opinions from
      # one component to another.
      class ImportOpinions < Rectify::Command
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

          broadcast(:ok, import_opinions)
        end

        private

        attr_reader :form

        def import_opinions
          opinions.map do |original_opinion|
            next if opinion_already_copied?(original_opinion, target_component)

            Decidim::Opinions::OpinionBuilder.copy(
              original_opinion,
              author: opinion_author,
              action_user: form.current_user,
              extra_attributes: {
                "component" => target_component
              }
            )
          end.compact
        end

        def opinions
          Decidim::Opinions::Opinion
            .where(component: origin_component)
            .where(state: opinion_states)
        end

        def opinion_states
          @opinion_states = @form.states

          if @form.states.include?("not_answered")
            @opinion_states.delete("not_answered")
            @opinion_states.push(nil)
          end

          @opinion_states
        end

        def origin_component
          @form.origin_component
        end

        def target_component
          @form.current_component
        end

        def opinion_already_copied?(original_opinion, target_component)
          original_opinion.linked_resources(:opinions, "copied_from_component").any? do |opinion|
            opinion.component == target_component
          end
        end

        def opinion_author
          form.keep_authors ? nil : @form.current_organization
        end
      end
    end
  end
end
