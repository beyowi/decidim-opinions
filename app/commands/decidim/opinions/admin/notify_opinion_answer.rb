# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A command to notify about the change of the published state for a opinion.
      class NotifyOpinionAnswer < Rectify::Command
        # Public: Initializes the command.
        #
        # opinion - The opinion to write the answer for.
        # initial_state - The opinion state before the current process.
        def initialize(opinion, initial_state)
          @opinion = opinion
          @initial_state = initial_state.to_s
        end

        # Executes the command. Broadcasts these events:
        #
        # - :noop when the answer is not published or the state didn't changed.
        # - :ok when everything is valid.
        #
        # Returns nothing.
        def call
          if opinion.published_state? && state_changed?
            transaction do
              increment_score
              notify_followers
            end
          end

          broadcast(:ok)
        end

        private

        attr_reader :opinion, :initial_state

        def state_changed?
          initial_state != opinion.state.to_s
        end

        def notify_followers
          if opinion.accepted?
            publish_event(
              "decidim.events.opinions.opinion_accepted",
              Decidim::Opinions::AcceptedOpinionEvent
            )
          elsif opinion.rejected?
            publish_event(
              "decidim.events.opinions.opinion_rejected",
              Decidim::Opinions::RejectedOpinionEvent
            )
          elsif opinion.evaluating?
            publish_event(
              "decidim.events.opinions.opinion_evaluating",
              Decidim::Opinions::EvaluatingOpinionEvent
            )
          end
        end

        def publish_event(event, event_class)
          Decidim::EventsManager.publish(
            event: event,
            event_class: event_class,
            resource: opinion,
            affected_users: opinion.notifiable_identities,
            followers: opinion.followers - opinion.notifiable_identities
          )
        end

        def increment_score
          if opinion.accepted?
            opinion.coauthorships.find_each do |coauthorship|
              Decidim::Gamification.increment_score(coauthorship.user_group || coauthorship.author, :accepted_opinions)
            end
          elsif initial_state == "accepted"
            opinion.coauthorships.find_each do |coauthorship|
              Decidim::Gamification.decrement_score(coauthorship.user_group || coauthorship.author, :accepted_opinions)
            end
          end
        end
      end
    end
  end
end
