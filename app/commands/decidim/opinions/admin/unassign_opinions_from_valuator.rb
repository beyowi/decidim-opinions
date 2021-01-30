# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A command with all the business logic to unassign opinions from a given
      # valuator.
      class UnassignOpinionsFromValuator < Rectify::Command
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

          unassign_opinions
          broadcast(:ok)
        end

        private

        attr_reader :form

        def unassign_opinions
          transaction do
            form.opinions.flat_map do |opinion|
              assignment = find_assignment(opinion)
              unassign(assignment) if assignment
            end
          end
        end

        def find_assignment(opinion)
          Decidim::Opinions::ValuationAssignment.find_by(
            opinion: opinion,
            valuator_role: form.valuator_role
          )
        end

        def unassign(assignment)
          Decidim.traceability.perform_action!(
            :delete,
            assignment,
            form.current_user,
            opinion_title: assignment.opinion.title
          ) do
            assignment.destroy!
          end
        end
      end
    end
  end
end
