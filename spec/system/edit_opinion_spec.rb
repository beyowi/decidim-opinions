# frozen_string_literal: true

require "spec_helper"

describe "Edit opinions", type: :system do
  include_context "with a component"
  let(:manifest_name) { "opinions" }

  let!(:user) { create :user, :confirmed, organization: participatory_process.organization }
  let!(:another_user) { create :user, :confirmed, organization: participatory_process.organization }
  let!(:opinion) { create :opinion, users: [user], component: component }

  before do
    switch_to_host user.organization.host
  end

  describe "editing my own opinion" do
    let(:new_title) { "This is my opinion new title" }
    let(:new_body) { "This is my opinion new body" }

    before do
      login_as user, scope: :user
    end

    it "can be updated" do
      visit_component

      click_link opinion.title
      click_link "Edit opinion"

      expect(page).to have_content "EDIT OPINION"

      within "form.edit_opinion" do
        fill_in :opinion_title, with: new_title
        fill_in :opinion_body, with: new_body
        click_button "Send"
      end

      expect(page).to have_content(new_title)
      expect(page).to have_content(new_body)
    end

    context "when updating with wrong data" do
      let(:component) { create(:opinion_component, :with_creation_enabled, :with_attachments_allowed, participatory_space: participatory_process) }

      it "returns an error message" do
        visit_component

        click_link opinion.title
        click_link "Edit opinion"

        expect(page).to have_content "EDIT OPINION"

        within "form.edit_opinion" do
          fill_in :opinion_body, with: "A"
          click_button "Send"
        end

        expect(page).to have_content("at least 15 characters", count: 1)
        expect(page).to have_content("is too short (under 15 characters)", count: 1)

        within "form.edit_opinion" do
          fill_in :opinion_body, with: "WE DO NOT WANT TO SHOUT IN THE OPINION BODY TEXT!"
          click_button "Send"
        end

        expect(page).to have_content("is using too many capital letters (over 25% of the text)")
      end

      it "keeps the submitted values" do
        visit_component

        click_link opinion.title
        click_link "Edit opinion"

        expect(page).to have_content "EDIT OPINION"

        within "form.edit_opinion" do
          fill_in :opinion_title, with: "A title with a #hashtag"
          fill_in :opinion_body, with: "ỲÓÜ WÄNTt TÙ ÚPDÀTÉ À PRÖPÔSÁL"
        end
        click_button "Send"

        expect(page).to have_selector("input[value='A title with a #hashtag']")
        expect(page).to have_content("ỲÓÜ WÄNTt TÙ ÚPDÀTÉ À PRÖPÔSÁL")
      end
    end
  end

  describe "editing someone else's opinion" do
    before do
      login_as another_user, scope: :user
    end

    it "renders an error" do
      visit_component

      click_link opinion.title
      expect(page).to have_no_content("Edit opinion")
      visit current_path + "/edit"

      expect(page).to have_content("not authorized")
    end
  end

  describe "editing my opinion outside the time limit" do
    let!(:opinion) { create :opinion, users: [user], component: component, created_at: 1.hour.ago }

    before do
      login_as another_user, scope: :user
    end

    it "renders an error" do
      visit_component

      click_link opinion.title
      expect(page).to have_no_content("Edit opinion")
      visit current_path + "/edit"

      expect(page).to have_content("not authorized")
    end
  end
end
