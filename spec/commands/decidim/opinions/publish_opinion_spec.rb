# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe PublishOpinion do
      describe "call" do
        let(:component) { create(:opinion_component) }
        let(:organization) { component.organization }
        let!(:current_user) { create(:user, organization: organization) }
        let(:follower) { create(:user, organization: organization) }
        let(:opinion_draft) { create(:opinion, :draft, component: component, users: [current_user]) }
        let!(:follow) { create :follow, followable: current_user, user: follower }

        it "broadcasts ok" do
          expect { described_class.call(opinion_draft, current_user) }.to broadcast(:ok)
        end

        it "scores on the opinions badge" do
          expect { described_class.call(opinion_draft, current_user) }.to change {
            Decidim::Gamification.status_for(current_user, :opinions).score
          }.by(1)
        end

        it "broadcasts invalid when the opinion is from another author" do
          expect { described_class.call(opinion_draft, follower) }.to broadcast(:invalid)
        end

        describe "events" do
          subject do
            described_class.new(opinion_draft, current_user)
          end

          it "notifies the opinion is published" do
            other_follower = create(:user, organization: organization)
            create(:follow, followable: component.participatory_space, user: follower)
            create(:follow, followable: component.participatory_space, user: other_follower)

            allow(Decidim::EventsManager).to receive(:publish)
              .with(hash_including(event: "decidim.events.gamification.badge_earned"))

            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.opinions.opinion_published",
                event_class: Decidim::Opinions::PublishOpinionEvent,
                resource: kind_of(Decidim::Opinions::Opinion),
                followers: [follower]
              )

            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.opinions.opinion_published",
                event_class: Decidim::Opinions::PublishOpinionEvent,
                resource: kind_of(Decidim::Opinions::Opinion),
                followers: [other_follower],
                extra: {
                  participatory_space: true
                }
              )

            subject.call
          end
        end
      end
    end
  end
end
