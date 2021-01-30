# frozen_string_literal: true

module Decidim
  module Opinions
    module Metrics
      # Searches for unique Users following the next objects
      #  - Opinions
      #  - CollaborativeDrafts
      class OpinionFollowersMetricMeasure < Decidim::MetricMeasure
        def valid?
          super && @resource.is_a?(Decidim::Component)
        end

        def calculate
          cumulative_users = []
          cumulative_users |= retrieve_opinions_followers.pluck(:decidim_user_id)
          cumulative_users |= retrieve_drafts_followers.pluck(:decidim_user_id)

          quantity_users = []
          quantity_users |= retrieve_opinions_followers(true).pluck(:decidim_user_id)
          quantity_users |= retrieve_drafts_followers(true).pluck(:decidim_user_id)

          {
            cumulative_users: cumulative_users.uniq,
            quantity_users: quantity_users.uniq
          }
        end

        private

        def retrieve_opinions_followers(from_start = false)
          @opinions_followers ||= Decidim::Follow.where(followable: retrieve_opinions).joins(:user)
                                                  .where("decidim_follows.created_at <= ?", end_time)

          return @opinions_followers.where("decidim_follows.created_at >= ?", start_time) if from_start

          @opinions_followers
        end

        def retrieve_drafts_followers(from_start = false)
          @drafts_followers ||= Decidim::Follow.where(followable: retrieve_collaborative_drafts).joins(:user)
                                               .where("decidim_follows.created_at <= ?", end_time)
          return @drafts_followers.where("decidim_follows.created_at >= ?", start_time) if from_start

          @drafts_followers
        end

        def retrieve_opinions
          Decidim::Opinions::Opinion.where(component: @resource).except_withdrawn
        end

        def retrieve_collaborative_drafts
          Decidim::Opinions::CollaborativeDraft.where(component: @resource).except_withdrawn
        end
      end
    end
  end
end
