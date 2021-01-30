# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A command with all the business logic to assign opinions to a given
      # valuator.
      class AssignOpinionsToValuator < Rectify::Command
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

          assign_opinions
          broadcast(:ok)
        rescue ActiveRecord::RecordInvalid
          broadcast(:invalid)
        end

        private

        attr_reader :form

        def assign_opinions
          transaction do
            form.opinions.flat_map do |opinion|
              find_assignment(opinion) || assign_opinion(opinion)
            end
          end
        end

        def find_assignment(opinion)
          Decidim::Opinions::ValuationAssignment.find_by(
            opinion: opinion,
            valuator_role: form.valuator_role
          )
        end

        def assign_opinion(opinion)
          Decidim.traceability.create!(
            Decidim::Opinions::ValuationAssignment,
            form.current_user,
            opinion: opinion,
            valuator_role: form.valuator_role
          )
        end
      end
    end
  end
end
