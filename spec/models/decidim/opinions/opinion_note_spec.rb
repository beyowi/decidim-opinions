# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe OpinionNote do
      subject { opinion_note }

      let!(:organization) { create(:organization) }
      let!(:component) { create(:component, organization: organization, manifest_name: "opinions") }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:author) { create(:user, :admin, organization: organization) }
      let!(:opinion) { create(:opinion, component: component, users: [author]) }
      let!(:opinion_note) { build(:opinion_note, opinion: opinion, author: author) }

      it { is_expected.to be_valid }
      it { is_expected.to be_versioned }

      it "has an associated author" do
        expect(opinion_note.author).to be_a(Decidim::User)
      end

      it "has an associated opinion" do
        expect(opinion_note.opinion).to be_a(Decidim::Opinions::Opinion)
      end
    end
  end
end
