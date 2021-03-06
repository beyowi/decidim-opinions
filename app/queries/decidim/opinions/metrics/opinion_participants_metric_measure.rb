# frozen_string_literal: true

module Decidim
  module Opinions
    module Metrics
      # Searches for Participants in the following actions
      #  - Create a opinion (Opinions)
      #  - Give support to a opinion (Opinions)
      #  - Endorse (Opinions)
      class OpinionParticipantsMetricMeasure < Decidim::MetricMeasure
        def valid?
          super && @resource.is_a?(Decidim::Component)
        end

        def calculate
          cumulative_users = []
          cumulative_users |= retrieve_votes.pluck(:decidim_author_id)
          cumulative_users |= retrieve_endorsements.pluck(:decidim_author_id)
          cumulative_users |= retrieve_opinions.pluck("decidim_coauthorships.decidim_author_id") # To avoid ambiguosity must be called this way

          quantity_users = []
          quantity_users |= retrieve_votes(true).pluck(:decidim_author_id)
          quantity_users |= retrieve_endorsements(true).pluck(:decidim_author_id)
          quantity_users |= retrieve_opinions(true).pluck("decidim_coauthorships.decidim_author_id") # To avoid ambiguosity must be called this way

          {
            cumulative_users: cumulative_users.uniq,
            quantity_users: quantity_users.uniq
          }
        end

        private

        def retrieve_opinions(from_start = false)
          @opinions ||= Decidim::Opinions::Opinion.where(component: @resource).joins(:coauthorships)
                                                     .includes(:votes, :endorsements)
                                                     .where(decidim_coauthorships: {
                                                              decidim_author_type: [
                                                                "Decidim::UserBaseEntity",
                                                                "Decidim::Organization",
                                                                "Decidim::Meetings::Meeting"
                                                              ]
                                                            })
                                                     .where("decidim_opinions_opinions.published_at <= ?", end_time)
                                                     .except_withdrawn

          return @opinions.where("decidim_opinions_opinions.published_at >= ?", start_time) if from_start

          @opinions
        end

        def retrieve_votes(from_start = false)
          @votes ||= Decidim::Opinions::OpinionVote.joins(:opinion).where(opinion: retrieve_opinions).joins(:author)
                                                     .where("decidim_opinions_opinion_votes.created_at <= ?", end_time)

          return @votes.where("decidim_opinions_opinion_votes.created_at >= ?", start_time) if from_start

          @votes
        end

        def retrieve_endorsements(from_start = false)
          @endorsements ||= Decidim::Endorsement.joins("INNER JOIN decidim_opinions_opinions opinions ON resource_id = opinions.id")
                                                .where(resource: retrieve_opinions)
                                                .where("decidim_endorsements.created_at <= ?", end_time)
                                                .where(decidim_author_type: "Decidim::UserBaseEntity")

          return @endorsements.where("decidim_endorsements.created_at >= ?", start_time) if from_start

          @endorsements
        end
      end
    end
  end
end
