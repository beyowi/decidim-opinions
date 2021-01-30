# frozen_string_literal: true

module Decidim
  module Opinions
    # A command with all the business logic when a user votes a opinion.
    class VoteOpinion < Rectify::Command
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
      # - :ok when everything is valid, together with the opinion vote.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if @opinion.maximum_votes_reached? && !@opinion.can_accumulate_supports_beyond_threshold

        build_opinion_vote
        return broadcast(:invalid) unless vote.valid?

        ActiveRecord::Base.transaction do
          @opinion.with_lock do
            vote.save!
            update_temporary_votes
          end
        end

        Decidim::Gamification.increment_score(@current_user, :opinion_votes)

        broadcast(:ok, vote)
      end

      attr_reader :vote

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
        return unless minimum_votes_per_user? && user_votes.count >= minimum_votes_per_user

        user_votes.each { |vote| vote.update(temporary: false) }
      end

      def user_votes
        @user_votes ||= OpinionVote.where(
          author: @current_user,
          opinion: Opinion.where(component: component)
        )
      end

      def build_opinion_vote
        @vote = @opinion.votes.build(
          author: @current_user,
          temporary: minimum_votes_per_user?
        )
      end
    end
  end
end
