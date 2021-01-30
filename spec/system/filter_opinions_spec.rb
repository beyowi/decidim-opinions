# frozen_string_literal: true

require "spec_helper"

describe "Filter Opinions", :slow, type: :system do
  include_context "with a component"
  let(:manifest_name) { "opinions" }

  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:scope) { create :scope, organization: organization }
  let!(:user) { create :user, :confirmed, organization: organization }
  let(:scoped_participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: scope) }

  context "when filtering opinions by ORIGIN" do
    context "when official_opinions setting is enabled" do
      before do
        component.update!(settings: { official_opinions_enabled: true })
      end

      it "can be filtered by origin" do
        visit_component

        within "form.new_filter" do
          expect(page).to have_content(/Origin/i)
        end
      end

      context "with 'official' origin" do
        it "lists the filtered opinions" do
          create_list(:opinion, 2, :official, component: component, scope: scope)
          create(:opinion, component: component, scope: scope)
          visit_component

          within ".filters .origin_check_boxes_tree_filter" do
            uncheck "All"
            check "Official"
          end

          expect(page).to have_css(".card--opinion", count: 2)
          expect(page).to have_content("2 OPINIONS")
        end
      end

      context "with 'citizens' origin" do
        it "lists the filtered opinions" do
          create_list(:opinion, 2, component: component, scope: scope)
          create(:opinion, :official, component: component, scope: scope)
          visit_component

          within ".filters .origin_check_boxes_tree_filter" do
            uncheck "All"
            check "Citizens"
          end

          expect(page).to have_css(".card--opinion", count: 2)
          expect(page).to have_content("2 OPINIONS")
        end
      end
    end

    context "when official_opinions setting is not enabled" do
      before do
        component.update!(settings: { official_opinions_enabled: false })
      end

      it "cannot be filtered by origin" do
        visit_component

        within "form.new_filter" do
          expect(page).to have_no_content(/Official/i)
        end
      end
    end
  end

  context "when filtering opinions by SCOPE" do
    let(:scopes_picker) { select_data_picker(:filter_scope_id, multiple: true, global_value: "global") }
    let!(:scope2) { create :scope, organization: participatory_process.organization }

    before do
      create_list(:opinion, 2, component: component, scope: scope)
      create(:opinion, component: component, scope: scope2)
      create(:opinion, component: component, scope: nil)
      visit_component
    end

    it "can be filtered by scope" do
      within "form.new_filter" do
        expect(page).to have_content(/Scope/i)
      end
    end

    context "when selecting the global scope" do
      it "lists the filtered opinions", :slow do
        within ".filters .scope_id_check_boxes_tree_filter" do
          uncheck "All"
          check "Global"
        end

        expect(page).to have_css(".card--opinion", count: 1)
        expect(page).to have_content("1 OPINION")
      end
    end

    context "when selecting one scope" do
      it "lists the filtered opinions", :slow do
        within ".filters .scope_id_check_boxes_tree_filter" do
          uncheck "All"
          check scope.name[I18n.locale.to_s]
        end

        expect(page).to have_css(".card--opinion", count: 2)
        expect(page).to have_content("2 OPINIONS")
      end
    end

    context "when selecting the global scope and another scope" do
      it "lists the filtered opinions", :slow do
        within ".filters .scope_id_check_boxes_tree_filter" do
          uncheck "All"
          check "Global"
          check scope.name[I18n.locale.to_s]
        end

        expect(page).to have_css(".card--opinion", count: 3)
        expect(page).to have_content("3 OPINIONS")
      end
    end

    context "when unselecting the selected scope" do
      it "lists the filtered opinions" do
        within ".filters .scope_id_check_boxes_tree_filter" do
          uncheck "All"
          check scope.name[I18n.locale.to_s]
          check "Global"
          uncheck scope.name[I18n.locale.to_s]
        end

        expect(page).to have_css(".card--opinion", count: 1)
        expect(page).to have_content("1 OPINION")
      end
    end

    context "when process is related to a scope" do
      let(:participatory_process) { scoped_participatory_process }

      it "cannot be filtered by scope" do
        visit_component

        within "form.new_filter" do
          expect(page).to have_no_content(/Scope/i)
        end
      end

      context "with subscopes" do
        let!(:subscopes) { create_list :subscope, 5, parent: scope }

        it "can be filtered by scope" do
          visit_component

          within "form.new_filter" do
            expect(page).to have_content(/Scope/i)
          end
        end
      end
    end
  end

  context "when filtering opinions by STATE" do
    context "when opinion_answering component setting is enabled" do
      before do
        component.update!(settings: { opinion_answering_enabled: true })
      end

      context "when opinion_answering step setting is enabled" do
        before do
          component.update!(
            step_settings: {
              component.participatory_space.active_step.id => {
                opinion_answering_enabled: true
              }
            }
          )
        end

        it "can be filtered by state" do
          visit_component

          within "form.new_filter" do
            expect(page).to have_content(/Status/i)
          end
        end

        it "lists accepted opinions" do
          create(:opinion, :accepted, component: component, scope: scope)
          visit_component

          within ".filters .state_check_boxes_tree_filter" do
            check "All"
            uncheck "All"
            check "Accepted"
          end

          expect(page).to have_css(".card--opinion", count: 1)
          expect(page).to have_content("1 OPINION")

          within ".card--opinion" do
            expect(page).to have_content("ACCEPTED")
          end
        end

        it "lists the filtered opinions" do
          create(:opinion, :rejected, component: component, scope: scope)
          visit_component

          within ".filters .state_check_boxes_tree_filter" do
            check "All"
            uncheck "All"
            check "Rejected"
          end

          expect(page).to have_css(".card--opinion", count: 1)
          expect(page).to have_content("1 OPINION")

          within ".card--opinion" do
            expect(page).to have_content("REJECTED")
          end
        end

        context "when there are opinions with answers not published" do
          let!(:opinion) { create(:opinion, :accepted_not_published, component: component, scope: scope) }

          before do
            create(:opinion, :accepted, component: component, scope: scope)

            visit_component
          end

          it "shows only accepted opinions with published answers" do
            within ".filters .state_check_boxes_tree_filter" do
              check "All"
              uncheck "All"
              check "Accepted"
            end

            expect(page).to have_css(".card--opinion", count: 1)
            expect(page).to have_content("1 OPINION")

            within ".card--opinion" do
              expect(page).to have_content("ACCEPTED")
            end
          end

          it "shows accepted opinions with not published answers as not answered" do
            within ".filters .state_check_boxes_tree_filter" do
              check "All"
              uncheck "All"
              check "Not answered"
            end

            expect(page).to have_css(".card--opinion", count: 1)
            expect(page).to have_content("1 OPINION")

            within ".card--opinion" do
              expect(page).to have_content(opinion.title)
              expect(page).not_to have_content("ACCEPTED")
            end
          end
        end
      end

      context "when opinion_answering step setting is disabled" do
        before do
          component.update!(
            step_settings: {
              component.participatory_space.active_step.id => {
                opinion_answering_enabled: false
              }
            }
          )
        end

        it "cannot be filtered by state" do
          visit_component

          within "form.new_filter" do
            expect(page).to have_no_content(/Status/i)
          end
        end
      end
    end

    context "when opinion_answering component setting is not enabled" do
      before do
        component.update!(settings: { opinion_answering_enabled: false })
      end

      it "cannot be filtered by state" do
        visit_component

        within "form.new_filter" do
          expect(page).to have_no_content(/Status/i)
        end
      end
    end
  end

  context "when filtering opinions by CATEGORY", :slow do
    context "when the user is logged in" do
      let!(:category2) { create :category, participatory_space: participatory_process }
      let!(:category3) { create :category, participatory_space: participatory_process }
      let!(:opinion1) { create(:opinion, component: component, category: category) }
      let!(:opinion2) { create(:opinion, component: component, category: category2) }
      let!(:opinion3) { create(:opinion, component: component, category: category3) }

      before do
        login_as user, scope: :user
      end

      it "can be filtered by a category" do
        visit_component

        within ".filters .category_id_check_boxes_tree_filter" do
          uncheck "All"
          check category.name[I18n.locale.to_s]
        end

        expect(page).to have_css(".card--opinion", count: 1)
      end

      it "can be filtered by two categories" do
        visit_component

        within ".filters .category_id_check_boxes_tree_filter" do
          uncheck "All"
          check category.name[I18n.locale.to_s]
          check category2.name[I18n.locale.to_s]
        end

        expect(page).to have_css(".card--opinion", count: 2)
      end
    end
  end

  context "when filtering opinions by ACTIVITY" do
    let(:active_step_id) { component.participatory_space.active_step.id }
    let!(:voted_opinion) { create(:opinion, component: component) }
    let!(:vote) { create(:opinion_vote, opinion: voted_opinion, author: user) }
    let!(:opinion_list) { create_list(:opinion, 3, component: component) }
    let!(:created_opinion) { create(:opinion, component: component, users: [user]) }

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
        visit_component
      end

      it "can be filtered by activity" do
        within "form.new_filter" do
          expect(page).to have_content(/Activity/i)
        end
      end

      it "can be filtered by my opinions" do
        within "form.new_filter" do
          expect(page).to have_content(/My opinions/i)
        end
      end

      it "lists the filtered opinions created by the user" do
        within "form.new_filter" do
          find("input[value='my_opinions']").click
        end
        expect(page).to have_css(".card--opinion", count: 1)
      end

      context "when votes are enabled" do
        before do
          component.update!(step_settings: { active_step_id => { votes_enabled: true } })
          visit_component
        end

        it "can be filtered by supported" do
          within "form.new_filter" do
            expect(page).to have_content(/Supported/i)
          end
        end

        it "lists the filtered opinions voted by the user" do
          within "form.new_filter" do
            find("input[value='voted']").click
          end

          expect(page).to have_css(".card--opinion", text: voted_opinion.title)
        end
      end

      context "when votes are not enabled" do
        before do
          component.update!(step_settings: { active_step_id => { votes_enabled: false } })
          visit_component
        end

        it "cannot be filtered by supported" do
          within "form.new_filter" do
            expect(page).not_to have_content(/Supported/i)
          end
        end
      end
    end

    context "when the user is NOT logged in" do
      it "cannot be filtered by activity" do
        visit_component
        within "form.new_filter" do
          expect(page).not_to have_content(/Activity/i)
        end
      end
    end
  end

  context "when filtering opinions by TYPE" do
    context "when there are amendments to opinions" do
      let!(:opinion) { create(:opinion, component: component, scope: scope) }
      let!(:emendation) { create(:opinion, component: component, scope: scope) }
      let!(:amendment) { create(:amendment, amendable: opinion, emendation: emendation) }

      before do
        visit_component
      end

      context "with 'all' type" do
        it "lists the filtered opinions" do
          find('input[name="filter[type]"][value="all"]').click

          expect(page).to have_css(".card.card--opinion", count: 2)
          expect(page).to have_content("2 OPINIONS")
          expect(page).to have_content("Amendment", count: 2)
        end
      end

      context "with 'opinions' type" do
        it "lists the filtered opinions" do
          within ".filters" do
            choose "Opinions"
          end

          expect(page).to have_css(".card.card--opinion", count: 1)
          expect(page).to have_content("1 OPINION")
          expect(page).to have_content("Amendment", count: 1)
        end
      end

      context "with 'amendments' type" do
        it "lists the filtered opinions" do
          within ".filters" do
            choose "Amendments"
          end

          expect(page).to have_css(".card.card--opinion", count: 1)
          expect(page).to have_content("1 OPINION")
          expect(page).to have_content("Amendment", count: 2)
        end
      end

      context "when amendments_enabled component setting is enabled" do
        before do
          component.update!(settings: { amendments_enabled: true })
        end

        context "and amendments_visbility component step_setting is set to 'participants'" do
          before do
            component.update!(
              step_settings: {
                component.participatory_space.active_step.id => {
                  amendments_visibility: "participants"
                }
              }
            )
          end

          context "when the user is logged in" do
            context "and has amended a opinion" do
              let!(:new_emendation) { create(:opinion, component: component, scope: scope) }
              let!(:new_amendment) { create(:amendment, amendable: opinion, emendation: new_emendation, amender: new_emendation.creator_author) }
              let(:user) { new_amendment.amender }

              before do
                login_as user, scope: :user
                visit_component
              end

              it "can be filtered by type" do
                within "form.new_filter" do
                  expect(page).to have_content(/Type/i)
                end
              end

              it "lists only their amendments" do
                within ".filters" do
                  choose "Amendments"
                end
                expect(page).to have_css(".card.card--opinion", count: 1)
                expect(page).to have_content("1 OPINION")
                expect(page).to have_content("Amendment", count: 2)
                expect(page).to have_content(new_emendation.title)
                expect(page).to have_no_content(emendation.title)
              end
            end

            context "and has NOT amended a opinion" do
              before do
                login_as user, scope: :user
                visit_component
              end

              it "cannot be filtered by type" do
                within "form.new_filter" do
                  expect(page).to have_no_content(/Type/i)
                end
              end
            end
          end

          context "when the user is NOT logged in" do
            before do
              visit_component
            end

            it "cannot be filtered by type" do
              within "form.new_filter" do
                expect(page).to have_no_content(/Type/i)
              end
            end
          end
        end
      end

      context "when amendments_enabled component setting is NOT enabled" do
        before do
          component.update!(settings: { amendments_enabled: false })
        end

        context "and amendments_visbility component step_setting is set to 'participants'" do
          before do
            component.update!(
              step_settings: {
                component.participatory_space.active_step.id => {
                  amendments_visibility: "participants"
                }
              }
            )
          end

          context "when the user is logged in" do
            context "and has amended a opinion" do
              let!(:new_emendation) { create(:opinion, component: component, scope: scope) }
              let!(:new_amendment) { create(:amendment, amendable: opinion, emendation: new_emendation, amender: new_emendation.creator_author) }
              let(:user) { new_amendment.amender }

              before do
                login_as user, scope: :user
                visit_component
              end

              it "can be filtered by type" do
                within "form.new_filter" do
                  expect(page).to have_content(/Type/i)
                end
              end

              it "lists all the amendments" do
                within ".filters" do
                  choose "Amendments"
                end
                expect(page).to have_css(".card.card--opinion", count: 2)
                expect(page).to have_content("2 OPINION")
                expect(page).to have_content("Amendment", count: 3)
                expect(page).to have_content(new_emendation.title)
                expect(page).to have_content(emendation.title)
              end
            end

            context "and has NOT amended a opinion" do
              before do
                login_as user, scope: :user
                visit_component
              end

              it "can be filtered by type" do
                within "form.new_filter" do
                  expect(page).to have_content(/Type/i)
                end
              end
            end
          end

          context "when the user is NOT logged in" do
            before do
              visit_component
            end

            it "can be filtered by type" do
              within "form.new_filter" do
                expect(page).to have_content(/Type/i)
              end
            end
          end
        end
      end
    end
  end

  context "when using the browser history", :slow do
    before do
      create_list(:opinion, 2, component: component)
      create_list(:opinion, 2, :official, component: component)
      create_list(:opinion, 2, :official, :accepted, component: component)
      create_list(:opinion, 2, :official, :rejected, component: component)

      visit_component
    end

    it "recover filters from initial pages" do
      within ".filters .state_check_boxes_tree_filter" do
        check "Rejected"
      end

      expect(page).to have_css(".card.card--opinion", count: 8)

      page.go_back

      expect(page).to have_css(".card.card--opinion", count: 6)
    end

    it "recover filters from previous pages" do
      within ".filters .state_check_boxes_tree_filter" do
        check "All"
        uncheck "All"
      end
      within ".filters .origin_check_boxes_tree_filter" do
        uncheck "All"
      end

      within ".filters .origin_check_boxes_tree_filter" do
        check "Official"
      end

      within ".filters .state_check_boxes_tree_filter" do
        check "Accepted"
      end

      expect(page).to have_css(".card.card--opinion", count: 2)

      page.go_back

      expect(page).to have_css(".card.card--opinion", count: 6)

      page.go_back

      expect(page).to have_css(".card.card--opinion", count: 8)

      page.go_forward

      expect(page).to have_css(".card.card--opinion", count: 6)
    end
  end
end
