# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe NotifyOpinionAnswer do
        subject { command.call }

        let(:command) { described_class.new(opinion, initial_state) }
        let(:opinion) { create(:opinion, :accepted) }
        let(:initial_state) { nil }
        let(:current_user) { create(:user, :admin) }
        let(:follow) { create(:follow, followable: opinion, user: follower) }
        let(:follower) { create(:user, organization: opinion.organization) }

        before do
          follow

          # give opinion author initial points to avoid unwanted events during tests
          Decidim::Gamification.increment_score(opinion.creator_author, :accepted_opinions)
        end

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "notifies the opinion followers" do
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.opinions.opinion_accepted",
              event_class: Decidim::Opinions::AcceptedOpinionEvent,
              resource: opinion,
              affected_users: match_array([opinion.creator_author]),
              followers: match_array([follower])
            )

          subject
        end

        it "increments the accepted opinions counter" do
          expect { subject }.to change { Gamification.status_for(opinion.creator_author, :accepted_opinions).score } .by(1)
        end

        context "when the opinion is rejected after being accepted" do
          let(:opinion) { create(:opinion, :rejected) }
          let(:initial_state) { "accepted" }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "notifies the opinion followers" do
            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.opinions.opinion_rejected",
                event_class: Decidim::Opinions::RejectedOpinionEvent,
                resource: opinion,
                affected_users: match_array([opinion.creator_author]),
                followers: match_array([follower])
              )

            subject
          end

          it "decrements the accepted opinions counter" do
            expect { subject }.to change { Gamification.status_for(opinion.coauthorships.first.author, :accepted_opinions).score } .by(-1)
          end
        end

        context "when the opinion published state has not changed" do
          let(:initial_state) { "accepted" }

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "doesn't notify the opinion followers" do
            expect(Decidim::EventsManager)
              .not_to receive(:publish)

            subject
          end

          it "doesn't modify the accepted opinions counter" do
            expect { subject }.not_to(change { Gamification.status_for(current_user, :accepted_opinions).score })
          end
        end
      end
    end
  end
end
