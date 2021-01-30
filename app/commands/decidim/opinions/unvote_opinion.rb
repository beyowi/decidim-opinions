# frozen_string_literal: true

module Decidim
  module Opinions
    # A command with all the business logic when a user unvotes a opinion.
    class UnvoteOpinion < Rectify::Command
      # Public: Initializes the command.
      #
      # opinion     - A Decidim::Opinions::Opinion object.
      # current_user - The current user.
      def initialize(opinion, current_user)
        @opinion = opinion
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the opinion.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        ActiveRecord::Base.transaction do
          OpinionVote.where(
            author: @current_user,
            opinion: @opinion
          ).destroy_all

          update_temporary_votes
        end

        Decidim::Gamification.decrement_score(@current_user, :opinion_votes)

        broadcast(:ok, @opinion)
      end

      private

      def component
        @component ||= @opinion.component
      end

      def minimum_votes_per_user
        component.settings.minimum_votes_per_user
      end

      def minimum_votes_per_user?
        minimum_votes_per_user.positive?
      end

      def update_temporary_votes
        return unless minimum_votes_per_user? && user_votes.count < minimum_votes_per_user

        user_votes.each { |vote| vote.update(temporary: true) }
      end

      def user_votes
        @user_votes ||= OpinionVote.where(
          author: @current_user,
          opinion: Opinion.where(component: component)
        )
      end
    end
  end
end
