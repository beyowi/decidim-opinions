# frozen_string_literal: true

require "spec_helper"

describe "Admin manages opinions valuators", type: :system do
  let(:manifest_name) { "opinions" }
  let!(:opinion) { create :opinion, component: current_component }
  let!(:reportables) { create_list(:opinion, 3, component: current_component) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
  let(:participatory_space_path) do
    decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
  end
  let!(:valuator) { create :user, organization: organization }
  let!(:valuator_role) { create :participatory_process_user_role, role: :valuator, user: valuator, participatory_process: participatory_process }

  include Decidim::ComponentPathHelper

  include_context "when managing a component as an admin"

  context "when assigning to a valuator" do
    before do
      visit current_path

      within find("tr", text: opinion.title) do
        page.first(".js-opinion-list-check").set(true)
      end

      click_button "Actions"
      click_button "Assign to valuator"
    end

    it "shows the component select" do
      expect(page).to have_css("#js-form-assign-opinions-to-valuator select", count: 1)
    end

    it "shows an update button" do
      expect(page).to have_css("button#js-submit-assign-opinions-to-valuator", count: 1)
    end

    context "when submitting the form" do
      before do
        within "#js-form-assign-opinions-to-valuator" do
          select valuator.name, from: :valuator_role_id
          page.find("button#js-submit-assign-opinions-to-valuator").click
        end
      end

      it "assigns the opinions to the valuator" do
        expect(page).to have_content("Opinions assigned to a valuator successfully")

        within find("tr", text: opinion.title) do
          expect(page).to have_selector("td.valuators-count", text: 1)
        end
      end
    end
  end

  context "when filtering opinions by assigned valuator" do
    let!(:unassigned_opinion) { create :opinion, component: component }
    let(:assigned_opinion) { opinion }

    before do
      create :valuation_assignment, opinion: opinion, valuator_role: valuator_role

      visit current_path
    end

    it "only shows the opinions assigned to the selected valuator" do
      expect(page).to have_content(assigned_opinion.title)
      expect(page).to have_content(unassigned_opinion.title)

      within ".filters__section" do
        find("a.dropdown", text: "Filter").hover
        find("a", text: "Assigned to valuator").hover
        find("a", text: valuator.name).click
      end

      expect(page).to have_content(assigned_opinion.title)
      expect(page).to have_no_content(unassigned_opinion.title)
    end
  end

  context "when unassigning valuators from a opinion from the opinions index page" do
    let(:assigned_opinion) { opinion }

    before do
      create :valuation_assignment, opinion: opinion, valuator_role: valuator_role

      visit current_path

      within find("tr", text: opinion.title) do
        page.first(".js-opinion-list-check").set(true)
      end

      click_button "Actions"
      click_button "Unassign from valuator"
    end

    it "shows the component select" do
      expect(page).to have_css("#js-form-unassign-opinions-from-valuator select", count: 1)
    end

    it "shows an update button" do
      expect(page).to have_css("button#js-submit-unassign-opinions-from-valuator", count: 1)
    end

    context "when submitting the form" do
      before do
        within "#js-form-unassign-opinions-from-valuator" do
          select valuator.name, from: :valuator_role_id
          page.find("button#js-submit-unassign-opinions-from-valuator").click
        end
      end

      it "unassigns the opinions to the valuator" do
        expect(page).to have_content("Valuator unassigned from opinions successfully")

        within find("tr", text: opinion.title) do
          expect(page).to have_selector("td.valuators-count", text: 0)
        end
      end
    end
  end

  context "when unassigning valuators from a opinion from the opinion show page" do
    let(:assigned_opinion) { opinion }

    before do
      create :valuation_assignment, opinion: opinion, valuator_role: valuator_role

      visit current_path

      find("a", text: opinion.title).click
    end

    it "can unassign a valuator" do
      within "#valuators" do
        expect(page).to have_content(valuator.name)

        accept_confirm do
          find("a.red-icon").click
        end
      end

      expect(page).to have_content("Valuator unassigned from opinions successfully")

      expect(page).to have_no_selector("#valuators")
    end
  end
end
