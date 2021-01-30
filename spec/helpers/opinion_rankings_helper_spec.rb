# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe OpinionRankingsHelper do
        let(:component) { create(:opinion_component) }

        let!(:opinion1) { create :opinion, component: component, opinion_votes_count: 4 }
        let!(:opinion2) { create :opinion, component: component, opinion_votes_count: 2 }
        let!(:opinion3) { create :opinion, component: component, opinion_votes_count: 2 }
        let!(:opinion4) { create :opinion, component: component, opinion_votes_count: 1 }

        let!(:external_opinion) { create :opinion, opinion_votes_count: 8 }

        describe "ranking_for" do
          it "returns the ranking considering only sibling opinions" do
            result = helper.ranking_for(opinion1, opinion_votes_count: :desc)

            expect(result).to eq(ranking: 1, total: 4)
          end

          it "breaks ties by ordering by ID" do
            result = helper.ranking_for(opinion3, opinion_votes_count: :desc)

            expect(result).to eq(ranking: 3, total: 4)
          end
        end
      end
    end
  end
end
