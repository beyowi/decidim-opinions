# frozen_string_literal: true

shared_examples "manage opinions" do
  let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: participatory_process_scope) }
  let(:participatory_process_scope) { nil }

  before do
    stub_geocoding(address, [latitude, longitude])
  end

  context "when previewing opinions" do
    it "allows the user to preview the opinion" do
      within find("tr", text: opinion.title) do
        klass = "action-icon--preview"
        href = resource_locator(opinion).path
        target = "blank"

        expect(page).to have_selector(
          :xpath,
          "//a[contains(@class,'#{klass}')][@href='#{href}'][@target='#{target}']"
        )
      end
    end
  end

  describe "creation" do
    context "when official_opinions setting is enabled" do
      before do
        current_component.update!(settings: { official_opinions_enabled: true })
      end

      context "when creation is enabled" do
        before do
          current_component.update!(
            step_settings: {
              current_component.participatory_space.active_step.id => {
                creation_enabled: true
              }
            }
          )

          visit_component_admin
        end

        describe "admin form" do
          before { click_on "New opinion" }

          it_behaves_like "having a rich text editor", "new_opinion", "full"
        end

        context "when process is not related to any scope" do
          it "can be related to a scope" do
            click_link "New opinion"

            within "form" do
              expect(page).to have_content(/Scope/i)
            end
          end

          it "creates a new opinion", :slow do
            click_link "New opinion"

            within ".new_opinion" do
              fill_in :opinion_title, with: "Make decidim great again"
              fill_in_editor :opinion_body, with: "Decidim is great but it can be better"
              select translated(category.name), from: :opinion_category_id
              scope_pick select_data_picker(:opinion_scope_id), scope
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              opinion = Decidim::Opinions::Opinion.last

              expect(page).to have_content("Make decidim great again")
              expect(opinion.body).to eq("<p>Decidim is great but it can be better</p>")
              expect(opinion.category).to eq(category)
              expect(opinion.scope).to eq(scope)
            end
          end
        end

        context "when process is related to a scope" do
          let(:participatory_process_scope) { scope }

          it "cannot be related to a scope, because it has no children" do
            click_link "New opinion"

            within "form" do
              expect(page).to have_no_content(/Scope/i)
            end
          end

          it "creates a new opinion related to the process scope" do
            click_link "New opinion"

            within ".new_opinion" do
              fill_in :opinion_title, with: "Make decidim great again"
              fill_in_editor :opinion_body, with: "Decidim is great but it can be better"
              select category.name["en"], from: :opinion_category_id
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              opinion = Decidim::Opinions::Opinion.last

              expect(page).to have_content("Make decidim great again")
              expect(opinion.body).to eq("<p>Decidim is great but it can be better</p>")
              expect(opinion.category).to eq(category)
              expect(opinion.scope).to eq(scope)
            end
          end

          context "when the process scope has a child scope" do
            let!(:child_scope) { create :scope, parent: scope }

            it "can be related to a scope" do
              click_link "New opinion"

              within "form" do
                expect(page).to have_content(/Scope/i)
              end
            end

            it "creates a new opinion related to a process scope child" do
              click_link "New opinion"

              within ".new_opinion" do
                fill_in :opinion_title, with: "Make decidim great again"
                fill_in_editor :opinion_body, with: "Decidim is great but it can be better"
                select category.name["en"], from: :opinion_category_id
                scope_repick select_data_picker(:opinion_scope_id), scope, child_scope
                find("*[type=submit]").click
              end

              expect(page).to have_admin_callout("successfully")

              within "table" do
                opinion = Decidim::Opinions::Opinion.last

                expect(page).to have_content("Make decidim great again")
                expect(opinion.body).to eq("<p>Decidim is great but it can be better</p>")
                expect(opinion.category).to eq(category)
                expect(opinion.scope).to eq(child_scope)
              end
            end
          end

          context "when geocoding is enabled" do
            before do
              current_component.update!(settings: { geocoding_enabled: true })
            end

            it "creates a new opinion related to the process scope" do
              click_link "New opinion"

              within ".new_opinion" do
                fill_in :opinion_title, with: "Make decidim great again"
                fill_in_editor :opinion_body, with: "Decidim is great but it can be better"
                fill_in :opinion_address, with: address
                select category.name["en"], from: :opinion_category_id
                find("*[type=submit]").click
              end

              expect(page).to have_admin_callout("successfully")

              within "table" do
                opinion = Decidim::Opinions::Opinion.last

                expect(page).to have_content("Make decidim great again")
                expect(opinion.body).to eq("<p>Decidim is great but it can be better</p>")
                expect(opinion.category).to eq(category)
                expect(opinion.scope).to eq(scope)
              end
            end
          end
        end

        context "when attachments are allowed", processing_uploads_for: Decidim::AttachmentUploader do
          before do
            current_component.update!(settings: { attachments_allowed: true })
          end

          it "creates a new opinion with attachments" do
            click_link "New opinion"

            within ".new_opinion" do
              fill_in :opinion_title, with: "Opinion with attachments"
              fill_in_editor :opinion_body, with: "This is my opinion and I want to upload attachments."
              fill_in :opinion_attachment_title, with: "My attachment"
              attach_file :opinion_attachment_file, Decidim::Dev.asset("city.jpeg")
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            visit resource_locator(Decidim::Opinions::Opinion.last).path
            expect(page).to have_selector("img[src*=\"city.jpeg\"]", count: 1)
          end
        end

        context "when opinions comes from a meeting" do
          let!(:meeting_component) { create(:meeting_component, participatory_space: participatory_process) }
          let!(:meetings) { create_list(:meeting, 3, component: meeting_component) }

          it "creates a new opinion with meeting as author" do
            click_link "New opinion"

            within ".new_opinion" do
              fill_in :opinion_title, with: "Opinion with meeting as author"
              fill_in_editor :opinion_body, with: "Opinion body of meeting as author"
              execute_script("$('#opinion_created_in_meeting').change()")
              find(:css, "#opinion_created_in_meeting").set(true)
              select translated(meetings.first.title), from: :opinion_meeting_id
              select category.name["en"], from: :opinion_category_id
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              opinion = Decidim::Opinions::Opinion.last

              expect(page).to have_content("Opinion with meeting as author")
              expect(opinion.body).to eq("<p>Opinion body of meeting as author</p>")
              expect(opinion.category).to eq(category)
            end
          end
        end
      end

      context "when creation is not enabled" do
        before do
          current_component.update!(
            step_settings: {
              current_component.participatory_space.active_step.id => {
                creation_enabled: false
              }
            }
          )
        end

        it "cannot create a new opinion from the main site" do
          visit_component
          expect(page).to have_no_button("New Opinion")
        end

        it "cannot create a new opinion from the admin site" do
          visit_component_admin
          expect(page).to have_no_link(/New/)
        end
      end
    end

    context "when official_opinions setting is disabled" do
      before do
        current_component.update!(settings: { official_opinions_enabled: false })
      end

      it "cannot create a new opinion from the main site" do
        visit_component
        expect(page).to have_no_button("New Opinion")
      end

      it "cannot create a new opinion from the admin site" do
        visit_component_admin
        expect(page).to have_no_link(/New/)
      end
    end
  end

  context "when the opinion_answering component setting is enabled" do
    before do
      current_component.update!(settings: { opinion_answering_enabled: true })
    end

    context "when the opinion_answering step setting is enabled" do
      before do
        current_component.update!(
          step_settings: {
            current_component.participatory_space.active_step.id => {
              opinion_answering_enabled: true
            }
          }
        )
      end

      it "can reject a opinion" do
        go_to_admin_opinion_page_answer_section(opinion)

        within ".edit_opinion_answer" do
          fill_in_i18n_editor(
            :opinion_answer_answer,
            "#opinion_answer-answer-tabs",
            en: "The opinion doesn't make any sense",
            es: "La propuesta no tiene sentido",
            ca: "La proposta no te sentit"
          )
          choose "Rejected"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Opinion successfully answered")

        within find("tr", text: opinion.title) do
          expect(page).to have_content("Rejected")
        end
      end

      it "can accept a opinion" do
        go_to_admin_opinion_page_answer_section(opinion)

        within ".edit_opinion_answer" do
          choose "Accepted"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Opinion successfully answered")

        within find("tr", text: opinion.title) do
          expect(page).to have_content("Accepted")
        end
      end

      it "can mark a opinion as evaluating" do
        go_to_admin_opinion_page_answer_section(opinion)

        within ".edit_opinion_answer" do
          choose "Evaluating"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Opinion successfully answered")

        within find("tr", text: opinion.title) do
          expect(page).to have_content("Evaluating")
        end
      end

      it "can edit a opinion answer" do
        opinion.update!(
          state: "rejected",
          answer: {
            "en" => "I don't like it"
          },
          answered_at: Time.current
        )

        visit_component_admin

        within find("tr", text: opinion.title) do
          expect(page).to have_content("Rejected")
        end

        go_to_admin_opinion_page_answer_section(opinion)

        within ".edit_opinion_answer" do
          choose "Accepted"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Opinion successfully answered")

        within find("tr", text: opinion.title) do
          expect(page).to have_content("Accepted")
        end
      end
    end

    context "when the opinion_answering step setting is disabled" do
      before do
        current_component.update!(
          step_settings: {
            current_component.participatory_space.active_step.id => {
              opinion_answering_enabled: false
            }
          }
        )
      end

      it "cannot answer a opinion" do
        visit current_path

        within find("tr", text: opinion.title) do
          expect(page).to have_no_link("Answer")
        end
      end
    end

    context "when the opinion is an emendation" do
      let!(:amendable) { create(:opinion, component: current_component) }
      let!(:emendation) { create(:opinion, component: current_component) }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation, state: "evaluating" }

      it "cannot answer a opinion" do
        visit_component_admin
        within find("tr", text: I18n.t("decidim/amendment", scope: "activerecord.models", count: 1)) do
          expect(page).to have_no_link("Answer")
        end
      end
    end
  end

  context "when the opinion_answering component setting is disabled" do
    before do
      current_component.update!(settings: { opinion_answering_enabled: false })
    end

    it "cannot answer a opinion" do
      go_to_admin_opinion_page(opinion)

      expect(page).to have_no_selector(".edit_opinion_answer")
    end
  end

  context "when the votes_enabled component setting is disabled" do
    before do
      current_component.update!(
        step_settings: {
          component.participatory_space.active_step.id => {
            votes_enabled: false
          }
        }
      )
    end

    it "doesn't show the votes column" do
      visit current_path

      within "thead" do
        expect(page).not_to have_content("VOTES")
      end
    end
  end

  context "when the votes_enabled component setting is enabled" do
    before do
      current_component.update!(
        step_settings: {
          component.participatory_space.active_step.id => {
            votes_enabled: true
          }
        }
      )
    end

    it "shows the votes column" do
      visit current_path

      within "thead" do
        expect(page).to have_content("Votes")
      end
    end
  end

  def go_to_admin_opinion_page(opinion)
    within find("tr", text: opinion.title) do
      find("a", class: "action-icon--show-opinion").click
    end
  end

  def go_to_admin_opinion_page_answer_section(opinion)
    go_to_admin_opinion_page(opinion)

    expect(page).to have_selector(".edit_opinion_answer")
  end
end
