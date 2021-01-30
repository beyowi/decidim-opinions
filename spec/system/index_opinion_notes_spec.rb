# frozen_string_literal: true

require "spec_helper"

describe "Index Opinion Notes", type: :system do
  let(:component) { create(:opinion_component) }
  let(:organization) { component.organization }

  let(:manifest_name) { "opinions" }
  let(:opinion) { create(:opinion, component: component) }
  let(:participatory_space) { component.participatory_space }

  let(:body) { "New awesome body" }
  let(:opinion_notes_count) { 5 }

  let!(:opinion_notes) do
    create_list(
      :opinion_note,
      opinion_notes_count,
      opinion: opinion
    )
  end

  include_context "when managing a component as an admin"

  before do
    within find("tr", text: opinion.title) do
      click_link "Answer opinion"
    end
  end

  it "shows opinion notes for the current opinion" do
    opinion_notes.each do |opinion_note|
      expect(page).to have_content(opinion_note.author.name)
      expect(page).to have_content(opinion_note.body)
    end
    expect(page).to have_selector("form")
  end

  context "when the form has a text inside body" do
    it "creates a opinion note ", :slow do
      within ".new_opinion_note" do
        fill_in :opinion_note_body, with: body

        find("*[type=submit]").click
      end

      expect(page).to have_admin_callout("successfully")

      within ".comment-thread .card:last-child" do
        expect(page).to have_content("New awesome body")
      end
    end
  end

  context "when the form hasn't text inside body" do
    let(:body) { nil }

    it "don't create a opinion note", :slow do
      within ".new_opinion_note" do
        fill_in :opinion_note_body, with: body

        find("*[type=submit]").click
      end

      expect(page).to have_content("There's an error in this field.")
    end
  end
end
