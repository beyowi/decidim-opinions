# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe Opinion do
      subject { opinion }

      let(:component) { build :opinion_component }
      let(:organization) { component.participatory_space.organization }
      let(:opinion) { create(:opinion, component: component) }
      let(:coauthorable) { opinion }

      include_examples "coauthorable"
      include_examples "has component"
      include_examples "has scope"
      include_examples "has category"
      include_examples "has reference"
      include_examples "reportable"
      include_examples "resourceable"

      it { is_expected.to be_valid }
      it { is_expected.to be_versioned }

      describe "newsletter participants" do
        subject { Decidim::Opinions::Opinion.newsletter_participant_ids(opinion.component) }

        let!(:component_out_of_newsletter) { create(:opinion_component, organization: organization) }
        let!(:resource_out_of_newsletter) { create(:opinion, component: component_out_of_newsletter) }
        let!(:resource_in_newsletter) { create(:opinion, component: opinion.component) }
        let(:author_ids) { opinion.notifiable_identities.pluck(:id) + resource_in_newsletter.notifiable_identities.pluck(:id) }

        include_examples "counts commentators as newsletter participants"
      end

      it "has a votes association returning opinion votes" do
        expect(subject.votes.count).to eq(0)
      end

      describe "#voted_by?" do
        let(:user) { create(:user, organization: subject.organization) }

        it "returns false if the opinion is not voted by the given user" do
          expect(subject).not_to be_voted_by(user)
        end

        it "returns true if the opinion is not voted by the given user" do
          create(:opinion_vote, opinion: subject, author: user)
          expect(subject).to be_voted_by(user)
        end
      end

      describe "#endorsed_by?" do
        let(:user) { create(:user, organization: subject.organization) }

        context "with User endorsement" do
          it "returns false if the opinion is not endorsed by the given user" do
            expect(subject).not_to be_endorsed_by(user)
          end

          it "returns true if the opinion is not endorsed by the given user" do
            create(:endorsement, resource: subject, author: user)
            expect(subject).to be_endorsed_by(user)
          end
        end

        context "with Organization endorsement" do
          let!(:user_group) { create(:user_group, verified_at: Time.current, organization: user.organization) }
          let!(:membership) { create(:user_group_membership, user: user, user_group: user_group) }

          before { user_group.reload }

          it "returns false if the opinion is not endorsed by the given organization" do
            expect(subject).not_to be_endorsed_by(user, user_group)
          end

          it "returns true if the opinion is not endorsed by the given organization" do
            create(:endorsement, resource: subject, author: user, user_group: user_group)
            expect(subject).to be_endorsed_by(user, user_group)
          end
        end
      end

      context "when it has been accepted" do
        let(:opinion) { build(:opinion, :accepted) }

        it { is_expected.to be_answered }
        it { is_expected.to be_published_state }
        it { is_expected.to be_accepted }
      end

      context "when it has been rejected" do
        let(:opinion) { build(:opinion, :rejected) }

        it { is_expected.to be_answered }
        it { is_expected.to be_published_state }
        it { is_expected.to be_rejected }
      end

      describe "#users_to_notify_on_comment_created" do
        let!(:follows) { create_list(:follow, 3, followable: subject) }
        let(:followers) { follows.map(&:user) }
        let(:participatory_space) { subject.component.participatory_space }
        let(:organization) { participatory_space.organization }
        let!(:participatory_process_admin) do
          create(:process_admin, participatory_process: participatory_space)
        end

        context "when the opinion is official" do
          let(:opinion) { build(:opinion, :official) }

          it "returns the followers and the component's participatory space admins" do
            expect(subject.users_to_notify_on_comment_created).to match_array(followers.concat([participatory_process_admin]))
          end
        end

        context "when the opinion is not official" do
          it "returns the followers and the author" do
            expect(subject.users_to_notify_on_comment_created).to match_array(followers.concat([opinion.creator.author]))
          end
        end
      end

      describe "#maximum_votes" do
        let(:maximum_votes) { 10 }

        context "when the component's settings are set to an integer bigger than 0" do
          before do
            component[:settings]["global"] = { threshold_per_opinion: 10 }
            component.save!
          end

          it "returns the maximum amount of votes for this opinion" do
            expect(opinion.maximum_votes).to eq(10)
          end
        end

        context "when the component's settings are set to 0" do
          before do
            component[:settings]["global"] = { threshold_per_opinion: 0 }
            component.save!
          end

          it "returns nil" do
            expect(opinion.maximum_votes).to be_nil
          end
        end
      end

      describe "#editable_by?" do
        let(:author) { create(:user, organization: organization) }

        context "when user is author" do
          let(:opinion) { create :opinion, component: component, users: [author], updated_at: Time.current }

          it { is_expected.to be_editable_by(author) }

          context "when the opinion has been linked to another one" do
            let(:opinion) { create :opinion, component: component, users: [author], updated_at: Time.current }
            let(:original_opinion) do
              original_component = create(:opinion_component, organization: organization, participatory_space: component.participatory_space)
              create(:opinion, component: original_component)
            end

            before do
              opinion.link_resources([original_opinion], "copied_from_component")
            end

            it { is_expected.not_to be_editable_by(author) }
          end
        end

        context "when opinion is from user group and user is admin" do
          let(:user_group) { create :user_group, :verified, users: [author], organization: author.organization }
          let(:opinion) { create :opinion, component: component, updated_at: Time.current, users: [author], user_groups: [user_group] }

          it { is_expected.to be_editable_by(author) }
        end

        context "when user is not the author" do
          let(:opinion) { create :opinion, component: component, updated_at: Time.current }

          it { is_expected.not_to be_editable_by(author) }
        end

        context "when opinion is answered" do
          let(:opinion) { build :opinion, :with_answer, component: component, updated_at: Time.current, users: [author] }

          it { is_expected.not_to be_editable_by(author) }
        end

        context "when opinion editing time has run out" do
          let(:opinion) { build :opinion, updated_at: 10.minutes.ago, component: component, users: [author] }

          it { is_expected.not_to be_editable_by(author) }
        end
      end

      describe "#withdrawn?" do
        context "when opinion is withdrawn" do
          let(:opinion) { build :opinion, :withdrawn }

          it { is_expected.to be_withdrawn }
        end

        context "when opinion is not withdrawn" do
          let(:opinion) { build :opinion }

          it { is_expected.not_to be_withdrawn }
        end
      end

      describe "#withdrawable_by" do
        let(:author) { create(:user, organization: organization) }

        context "when user is author" do
          let(:opinion) { create :opinion, component: component, users: [author], created_at: Time.current }

          it { is_expected.to be_withdrawable_by(author) }
        end

        context "when user is admin" do
          let(:admin) { build(:user, :admin, organization: organization) }
          let(:opinion) { build :opinion, component: component, users: [author], created_at: Time.current }

          it { is_expected.not_to be_withdrawable_by(admin) }
        end

        context "when user is not the author" do
          let(:someone_else) { build(:user, organization: organization) }
          let(:opinion) { build :opinion, component: component, users: [author], created_at: Time.current }

          it { is_expected.not_to be_withdrawable_by(someone_else) }
        end

        context "when opinion is already withdrawn" do
          let(:opinion) { build :opinion, :withdrawn, component: component, users: [author], created_at: Time.current }

          it { is_expected.not_to be_withdrawable_by(author) }
        end

        context "when the opinion has been linked to another one" do
          let(:opinion) { create :opinion, component: component, users: [author], created_at: Time.current }
          let(:original_opinion) do
            original_component = create(:opinion_component, organization: organization, participatory_space: component.participatory_space)
            create(:opinion, component: original_component)
          end

          before do
            opinion.link_resources([original_opinion], "copied_from_component")
          end

          it { is_expected.not_to be_withdrawable_by(author) }
        end
      end

      context "when answer is not published" do
        let(:opinion) { create(:opinion, :accepted_not_published, component: component) }

        it "has accepted as the internal state" do
          expect(opinion.internal_state).to eq("accepted")
        end

        it "has not_answered as public state" do
          expect(opinion.state).to be_nil
        end

        it { is_expected.not_to be_accepted }
        it { is_expected.to be_answered }
        it { is_expected.not_to be_published_state }
      end

      describe "#with_valuation_assigned_to" do
        let(:user) { create :user, organization: organization }
        let(:space) { component.participatory_space }
        let!(:valuator_role) { create :participatory_process_user_role, role: :valuator, user: user, participatory_process: space }
        let(:assigned_opinion) { create :opinion, component: component }
        let!(:assignment) { create :valuation_assignment, opinion: assigned_opinion, valuator_role: valuator_role }

        it "only returns the assigned opinions for the given space" do
          results = described_class.with_valuation_assigned_to(user, space)

          expect(results).to eq([assigned_opinion])
        end
      end
    end
  end
end
