# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe WithdrawOpinion do
      let(:opinion) { create(:opinion) }

      before do
        opinion.save!
      end

      describe "when current user IS the author of the opinion" do
        let(:current_user) { opinion.creator_author }
        let(:command) { described_class.new(opinion, current_user) }

        context "and the opinion has no supports" do
          it "withdraws the opinion" do
            expect do
              expect { command.call }.to broadcast(:ok)
            end.to change { Decidim::Opinions::Opinion.count }.by(0)
            expect(opinion.state).to eq("withdrawn")
          end
        end

        context "and the opinion HAS some supports" do
          before do
            opinion.votes.create!(author: current_user)
          end

          it "is not able to withdraw the opinion" do
            expect do
              expect { command.call }.to broadcast(:has_supports)
            end.to change { Decidim::Opinions::Opinion.count }.by(0)
            expect(opinion.state).not_to eq("withdrawn")
          end
        end
      end
    end
  end
end
