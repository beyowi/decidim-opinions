# frozen_string_literal: true

module Decidim
  module Opinions
    # A command with all the business logic when a user publishes a draft opinion.
    class PublishOpinion < Rectify::Command
      # Public: Initializes the command.
      #
      # opinion     - The opinion to publish.
      # current_user - The current user.
      def initialize(opinion, current_user)
        @opinion = opinion
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the opinion is published.
      # - :invalid if the opinion's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) unless @opinion.authored_by?(@current_user)

        transaction do
          publish_opinion
          increment_scores
          send_notification
          send_notification_to_participatory_space
        end

        broadcast(:ok, @opinion)
      end

      private

      # This will be the PaperTrail version that is
      # shown in the version control feature (1 of 1)
      #
      # For an attribute to appear in the new version it has to be reset
      # and reassigned, as PaperTrail only keeps track of object CHANGES.
      def publish_opinion
        title = reset(:title)
        body = reset(:body)

        Decidim.traceability.perform_action!(
          "publish",
          @opinion,
          @current_user,
          visibility: "public-only"
        ) do
          @opinion.update title: title, body: body, published_at: Time.current
        end
      end

      # Reset the attribute to an empty string and return the old value
      def reset(attribute)
        attribute_value = @opinion[attribute]
        PaperTrail.request(enabled: false) do
          # rubocop:disable Rails/SkipsModelValidations
          @opinion.update_attribute attribute, ""
          # rubocop:enable Rails/SkipsModelValidations
        end
        attribute_value
      end

      def send_notification
        return if @opinion.coauthorships.empty?

        Decidim::EventsManager.publish(
          event: "decidim.events.opinions.opinion_published",
          event_class: Decidim::Opinions::PublishOpinionEvent,
          resource: @opinion,
          followers: coauthors_followers
        )
      end

      def send_notification_to_participatory_space
        Decidim::EventsManager.publish(
          event: "decidim.events.opinions.opinion_published",
          event_class: Decidim::Opinions::PublishOpinionEvent,
          resource: @opinion,
          followers: @opinion.participatory_space.followers - coauthors_followers,
          extra: {
            participatory_space: true
          }
        )
      end

      def coauthors_followers
        @coauthors_followers ||= @opinion.authors.flat_map(&:followers)
      end

      def increment_scores
        @opinion.coauthorships.find_each do |coauthorship|
          if coauthorship.user_group
            Decidim::Gamification.increment_score(coauthorship.user_group, :opinions)
          else
            Decidim::Gamification.increment_score(coauthorship.author, :opinions)
          end
        end
      end
    end
  end
end
