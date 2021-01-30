# frozen_string_literal: true

require "spec_helper"

describe "show", type: :system do
  include_context "with a component"
  let(:manifest_name) { "opinions" }

  let!(:opinion) { create(:opinion, component: component) }

  before do
    visit_component
    click_link opinion.title[I18n.locale.to_s], class: "card__link"
  end

  context "when shows the opinion component" do
    it "shows the opinion title" do
      expect(page).to have_content opinion.title[I18n.locale.to_s]
    end

    it_behaves_like "going back to list button"
  end
end
