# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe OpinionVote do
      subject { opinion_vote }

      let!(:organization) { create(:organization) }
      let!(:component) { create(:component, organization: organization, manifest_name: "opinions") }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:author) { create(:user, organization: organization) }
      let!(:opinion) { create(:opinion, component: component, users: [author]) }
      let!(:opinion_vote) { build(:opinion_vote, opinion: opinion, author: author) }

      it "is valid" do
        expect(opinion_vote).to be_valid
      end

      it "has an associated author" do
        expect(opinion_vote.author).to be_a(Decidim::User)
      end

      it "has an associated opinion" do
        expect(opinion_vote.opinion).to be_a(Decidim::Opinions::Opinion)
      end

      it "validates uniqueness for author and opinion combination" do
        opinion_vote.save!
        expect do
          create(:opinion_vote, opinion: opinion, author: author)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      context "when no author" do
        before do
          opinion_vote.author = nil
        end

        it { is_expected.to be_invalid }
      end

      context "when no opinion" do
        before do
          opinion_vote.opinion = nil
        end

        it { is_expected.to be_invalid }
      end

      context "when opinion and author have different organization" do
        let(:other_author) { create(:user) }
        let(:other_opinion) { create(:opinion) }

        it "is invalid" do
          opinion_vote = build(:opinion_vote, opinion: other_opinion, author: other_author)
          expect(opinion_vote).to be_invalid
        end
      end

      context "when opinion is rejected" do
        let!(:opinion) { create(:opinion, :rejected, component: component, users: [author]) }

        it { is_expected.to be_invalid }
      end
    end
  end
end
