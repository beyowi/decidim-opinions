# frozen_string_literal: true

require "spec_helper"

describe "Opinion", type: :system do
  include_context "with a component"
  let(:manifest_name) { "opinions" }
  let(:organization) { create :organization }

  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:scope) { create :scope, organization: organization }
  let!(:user) { create :user, :confirmed, organization: organization }
  let(:scoped_participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: scope) }

  let(:address) { "Plaça Santa Jaume, 1, 08002 Barcelona" }
  let(:latitude) { 41.3825 }
  let(:longitude) { 2.1772 }

  let(:opinion_title) { "More sidewalks and less roads" }
  let(:opinion_body) { "Cities need more people, not more cars" }

  let!(:component) do
    create(:opinion_component,
           :with_creation_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end
  let(:component_path) { Decidim::EngineRouter.main_proxy(component) }

  context "when creating a new opinion" do
    before do
      login_as user, scope: :user
      visit_component
      click_link "New opinion"
    end

    context "when in step_1: Create your opinion" do
      it "show current step_1 highlighted" do
        within ".wizard__steps" do
          expect(page).to have_css(".step--active", count: 1)
          expect(page).to have_css(".step--past", count: 0)
          expect(page).to have_css(".step--active.step_1")
        end
      end

      it "fill in title and body" do
        within ".card__content form" do
          fill_in :opinion_title, with: opinion_title
          fill_in :opinion_body, with: opinion_body
          find("*[type=submit]").click
        end
      end

      context "when the back button is clicked" do
        before do
          click_link "Back"
        end

        it "redirects to opinions_path" do
          expect(page).to have_content("OPINIONS")
          expect(page).to have_content("New opinion")
        end
      end
    end

    context "when in step_2: Compare" do
      context "with similar results" do
        before do
          create(:opinion, title: "More sidewalks and less roads", body: "Cities need more people, not more cars", component: component)
          create(:opinion, title: "More sidewalks and less roadways", body: "Green is always better", component: component)
          visit_component
          click_link "New opinion"
          within ".new_opinion" do
            fill_in :opinion_title, with: opinion_title
            fill_in :opinion_body, with: opinion_body

            find("*[type=submit]").click
          end
        end

        it "show previous and current step_2 highlighted" do
          within ".wizard__steps" do
            expect(page).to have_css(".step--active", count: 1)
            expect(page).to have_css(".step--past", count: 1)
            expect(page).to have_css(".step--active.step_2")
          end
        end

        it "shows similar opinions" do
          expect(page).to have_content("SIMILAR OPINIONS (2)")
          expect(page).to have_css(".card--opinion", text: "More sidewalks and less roads")
          expect(page).to have_css(".card--opinion", count: 2)
        end

        it "show continue button" do
          expect(page).to have_link("Continue")
        end

        it "does not show the back button" do
          expect(page).not_to have_link("Back")
        end
      end

      context "without similar results" do
        before do
          visit_component
          click_link "New opinion"
          within ".new_opinion" do
            fill_in :opinion_title, with: opinion_title
            fill_in :opinion_body, with: opinion_body

            find("*[type=submit]").click
          end
        end

        it "redirects to step_3: complete" do
          within ".section-heading" do
            expect(page).to have_content("COMPLETE YOUR OPINION")
          end
          expect(page).to have_css(".edit_opinion")
        end

        it "shows no similar opinion found callout" do
          within ".flash.callout.success" do
            expect(page).to have_content("Well done! No similar opinions found")
          end
        end
      end
    end

    context "when in step_3: Complete" do
      before do
        visit_component
        click_link "New opinion"
        within ".new_opinion" do
          fill_in :opinion_title, with: opinion_title
          fill_in :opinion_body, with: opinion_body

          find("*[type=submit]").click
        end
      end

      it "show previous and current step_3 highlighted" do
        within ".wizard__steps" do
          expect(page).to have_css(".step--active", count: 1)
          expect(page).to have_css(".step--past", count: 2)
          expect(page).to have_css(".step--active.step_3")
        end
      end

      it "show form and submit button" do
        expect(page).to have_field("Title", with: opinion_title)
        expect(page).to have_field("Body", with: opinion_body)
        expect(page).to have_button("Send")
      end

      context "when the back button is clicked" do
        before do
          create(:opinion, title: opinion_title, component: component)
          click_link "Back"
        end

        it "redirects to step_3: complete" do
          expect(page).to have_content("SIMILAR OPINIONS (1)")
        end
      end
    end

    context "when in step_4: Publish" do
      let!(:opinion_draft) { create(:opinion, :draft, users: [user], component: component, title: opinion_title, body: opinion_body) }

      before do
        visit component_path.preview_opinion_path(opinion_draft)
      end

      it "show current step_4 highlighted" do
        within ".wizard__steps" do
          expect(page).to have_css(".step--active", count: 1)
          expect(page).to have_css(".step--past", count: 3)
          expect(page).to have_css(".step--active.step_4")
        end
      end

      it "shows a preview" do
        expect(page).to have_content(opinion_title)
        expect(page).to have_content(user.name)
        expect(page).to have_content(opinion_body)
      end

      it "shows a publish button" do
        expect(page).to have_selector("button", text: "Publish")
      end

      it "shows a modify opinion link" do
        expect(page).to have_selector("a", text: "Modify the opinion")
      end

      context "when the back button is clicked" do
        before do
          click_link "Back"
        end

        it "redirects to edit the opinion draft" do
          expect(page).to have_content("EDIT OPINION DRAFT")
        end
      end
    end

    context "when editing a opinion draft" do
      context "when in step_4: edit opinion draft" do
        let!(:opinion_draft) { create(:opinion, :draft, users: [user], component: component, title: opinion_title, body: opinion_body) }
        let!(:edit_draft_opinion_path) do
          Decidim::EngineRouter.main_proxy(component).opinion_path(opinion_draft) + "/edit_draft"
        end

        before do
          visit edit_draft_opinion_path
        end

        it "show current step_4 highlighted" do
          within ".wizard__steps" do
            expect(page).to have_css(".step--active", count: 1)
            expect(page).to have_css(".step--past", count: 2)
            expect(page).to have_css(".step--active.step_3")
          end
        end

        it "can discard the draft" do
          within ".card__content" do
            expect(page).to have_content("Discard this draft")
            click_link "Discard this draft"
          end

          accept_confirm

          within_flash_messages do
            expect(page).to have_content "successfully"
          end
          expect(page).to have_css(".step--active.step_1")
        end

        it "renders a Preview button" do
          within ".card__content" do
            expect(page).to have_content("Preview")
          end
        end
      end
    end
  end
end
