# frozen_string_literal: true

require "spec_helper"

describe "Index opinions", type: :system do
  include_context "with a component"
  let(:manifest_name) { "opinions" }

  context "when there are opinions" do
    let!(:opinions) { create_list(:opinion, 3, component: component) }

    it "doesn't display empty message" do
      visit_component

      expect(page).to have_no_content("There is no opinion yet")
    end
  end

  context "when there are no opinions" do
    context "when there are no filters" do
      it "shows generic empty message" do
        visit_component

        expect(page).to have_content("There is no opinion yet")
      end
    end

    context "when there are filters" do
      let!(:opinions) { create(:opinion, :with_answer, :accepted, component: component) }

      it "shows filters empty message" do
        visit_component

        uncheck "Accepted"

        expect(page).to have_content("There isn't any opinion with this criteria")
      end
    end
  end
end
