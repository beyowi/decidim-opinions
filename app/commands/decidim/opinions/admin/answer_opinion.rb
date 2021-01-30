# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A command with all the business logic when an admin answers a opinion.
      class AnswerOpinion < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        # opinion - The opinion to write the answer for.
        def initialize(form, opinion)
          @form = form
          @opinion = opinion
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          store_initial_opinion_state

          transaction do
            answer_opinion
            notify_opinion_answer
          end

          broadcast(:ok)
        end

        private

        attr_reader :form, :opinion, :initial_has_state_published, :initial_state

        def answer_opinion
          Decidim.traceability.perform_action!(
            "answer",
            opinion,
            form.current_user
          ) do
            attributes = {
              state: form.state,
              answer: form.answer,
              answered_at: Time.current,
              cost: form.cost,
              cost_report: form.cost_report,
              execution_period: form.execution_period
            }

            attributes[:state_published_at] = Time.current if !initial_has_state_published && form.publish_answer?

            opinion.update!(attributes)
          end
        end

        def notify_opinion_answer
          return if !initial_has_state_published && !form.publish_answer?

          NotifyOpinionAnswer.call(opinion, initial_state)
        end

        def store_initial_opinion_state
          @initial_has_state_published = opinion.published_state?
          @initial_state = opinion.state
        end
      end
    end
  end
end
