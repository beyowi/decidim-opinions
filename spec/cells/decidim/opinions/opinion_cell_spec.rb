# frozen_string_literal: true

require "spec_helper"

describe Decidim::Opinions::OpinionCell, type: :cell do
  controller Decidim::Opinions::OpinionsController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/opinions/opinion", model) }
  let!(:official_opinion) { create(:opinion, :official) }
  let!(:user_opinion) { create(:opinion) }
  let!(:current_user) { create(:user, :confirmed, organization: model.participatory_space.organization) }

  before do
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  context "when rendering an official opinion" do
    let(:model) { official_opinion }

    it "renders the card" do
      expect(subject).to have_css(".card--opinion")
    end
  end

  context "when rendering a user opinion" do
    let(:model) { user_opinion }

    it "renders the card" do
      expect(subject).to have_css(".card--opinion")
    end
  end
end
