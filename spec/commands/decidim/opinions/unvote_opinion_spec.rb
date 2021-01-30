# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe UnvoteOpinion do
      describe "call" do
        let(:opinion) { create(:opinion) }
        let(:current_user) { create(:user, organization: opinion.component.organization) }
        let!(:opinion_vote) { create(:opinion_vote, author: current_user, opinion: opinion) }
        let(:command) { described_class.new(opinion, current_user) }

        it "broadcasts ok" do
          expect { command.call }.to broadcast(:ok)
        end

        it "deletes the opinion vote for that user" do
          expect do
            command.call
          end.to change(OpinionVote, :count).by(-1)
        end

        it "decrements the right score for that user" do
          Decidim::Gamification.set_score(current_user, :opinion_votes, 10)
          command.call
          expect(Decidim::Gamification.status_for(current_user, :opinion_votes).score).to eq(9)
        end
      end
    end
  end
end
