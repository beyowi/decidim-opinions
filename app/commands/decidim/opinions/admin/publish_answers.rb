# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A command with all the business logic to publish many answers at once.
      class PublishAnswers < Rectify::Command
        # Public: Initializes the command.
        #
        # component - The component that contains the answers.
        # user - the Decidim::User that is publishing the answers.
        # opinion_ids - the identifiers of the opinions with the answers to be published.
        def initialize(component, user, opinion_ids)
          @component = component
          @user = user
          @opinion_ids = opinion_ids
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if there are not opinions to publish.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless opinions.any?

          opinions.each do |opinion|
            transaction do
              mark_opinion_as_answered(opinion)
              notify_opinion_answer(opinion)
            end
          end

          broadcast(:ok)
        end

        private

        attr_reader :component, :user, :opinion_ids

        def opinions
          @opinions ||= Decidim::Opinions::Opinion
                         .published
                         .answered
                         .state_not_published
                         .where(component: component)
                         .where(id: opinion_ids)
        end

        def mark_opinion_as_answered(opinion)
          Decidim.traceability.perform_action!(
            "publish_answer",
            opinion,
            user
          ) do
            opinion.update!(state_published_at: Time.current)
          end
        end

        def notify_opinion_answer(opinion)
          NotifyOpinionAnswer.call(opinion, nil)
        end
      end
    end
  end
end
