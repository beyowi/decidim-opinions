# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # This class contains helpers needed to get rankings for a given opinion
      # ordered by some given criteria.
      #
      module OpinionRankingsHelper
        # Public: Gets the ranking for a given opinion, ordered by some given
        # criteria. Opinion is sorted amongst its own siblings.
        #
        # Returns a Hash with two keys:
        #   :ranking - an Integer representing the ranking for the given opinion.
        #     Ranking starts with 1.
        #   :total - an Integer representing the total number of ranked opinions.
        #
        # Examples:
        #   ranking_for(opinion, opinion_votes_count: :desc)
        #   ranking_for(opinion, endorsements_count: :desc)
        def ranking_for(opinion, order = {})
          siblings = Decidim::Opinions::Opinion.where(component: opinion.component)
          ranked = siblings.order([order, id: :asc])
          ranked_ids = ranked.pluck(:id)

          { ranking: ranked_ids.index(opinion.id) + 1, total: ranked_ids.count }
        end

        # Public: Gets the ranking for a given opinion, ordered by endorsements.
        def endorsements_ranking_for(opinion)
          ranking_for(opinion, endorsements_count: :desc)
        end

        # Public: Gets the ranking for a given opinion, ordered by votes.
        def votes_ranking_for(opinion)
          ranking_for(opinion, opinion_votes_count: :desc)
        end

        def i18n_endorsements_ranking_for(opinion)
          rankings = endorsements_ranking_for(opinion)

          I18n.t(
            "ranking",
            scope: "decidim.opinions.admin.opinions.show",
            ranking: rankings[:ranking],
            total: rankings[:total]
          )
        end

        def i18n_votes_ranking_for(opinion)
          rankings = votes_ranking_for(opinion)

          I18n.t(
            "ranking",
            scope: "decidim.opinions.admin.opinions.show",
            ranking: rankings[:ranking],
            total: rankings[:total]
          )
        end
      end
    end
  end
end
