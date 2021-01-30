# frozen_string_literal: true

module Decidim
  module Opinions
    # A opinion can include a vote per user.
    class OpinionVote < ApplicationRecord
      belongs_to :opinion, foreign_key: "decidim_opinion_id", class_name: "Decidim::Opinions::Opinion"
      belongs_to :author, foreign_key: "decidim_author_id", class_name: "Decidim::User"

      validates :opinion, uniqueness: { scope: :author }
      validate :author_and_opinion_same_organization
      validate :opinion_not_rejected

      after_save :update_opinion_votes_count
      after_destroy :update_opinion_votes_count

      # Temporary votes are used when a minimum amount of votes is configured in
      # a component. They aren't taken into account unless the amount of votes
      # exceeds a threshold - meanwhile, they're marked as temporary.
      def self.temporary
        where(temporary: true)
      end

      # Final votes are votes that will be taken into account, that is, they're
      # not temporary.
      def self.final
        where(temporary: false)
      end

      private

      def update_opinion_votes_count
        opinion.update_votes_count
      end

      # Private: check if the opinion and the author have the same organization
      def author_and_opinion_same_organization
        return if !opinion || !author

        errors.add(:opinion, :invalid) unless author.organization == opinion.organization
      end

      def opinion_not_rejected
        return unless opinion

        errors.add(:opinion, :invalid) if opinion.rejected?
      end
    end
  end
end
