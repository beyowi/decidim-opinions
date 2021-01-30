# frozen_string_literal: true

require "spec_helper"

describe "Support Opinion", type: :system, slow: true do
  include_context "with a component"
  let(:manifest_name) { "opinions" }

  let!(:opinions) { create_list(:opinion, 3, component: component) }
  let!(:opinion) { Decidim::Opinions::Opinion.find_by(component: component) }
  let!(:user) { create :user, :confirmed, organization: organization }

  def expect_page_not_to_include_votes
    expect(page).to have_no_button("Support")
    expect(page).to have_no_css(".card__support__data span", text: "0 Supports")
  end

  context "when votes are not enabled" do
    context "when the user is not logged in" do
      it "doesn't show the vote opinion button and counts" do
        visit_component
        expect_page_not_to_include_votes

        click_link opinion.title
        expect_page_not_to_include_votes
      end
    end

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
      end

      it "doesn't show the vote opinion button and counts" do
        visit_component
        expect_page_not_to_include_votes

        click_link opinion.title
        expect_page_not_to_include_votes
      end
    end
  end

  context "when votes are blocked" do
    let!(:component) do
      create(:opinion_component,
             :with_votes_blocked,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    it "shows the vote count and the vote button is disabled" do
      visit_component
      expect_page_not_to_include_votes
    end
  end

  context "when votes are enabled" do
    let!(:component) do
      create(:opinion_component,
             :with_votes_enabled,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    context "when the user is not logged in" do
      it "is given the option to sign in" do
        visit_component

        within ".card__support", match: :first do
          click_button "Support"
        end

        expect(page).to have_css("#loginModal", visible: :visible)
      end
    end

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
      end

      context "when the opinion is not voted yet" do
        before do
          visit_component
        end

        it "is able to vote the opinion" do
          within "#opinion-#{opinion.id}-vote-button" do
            click_button "Support"
            expect(page).to have_button("Already supported")
          end

          within "#opinion-#{opinion.id}-votes-count" do
            expect(page).to have_content("1 Support")
          end
        end
      end

      context "when the opinion is already voted" do
        before do
          create(:opinion_vote, opinion: opinion, author: user)
          visit_component
        end

        it "is not able to vote it again" do
          within "#opinion-#{opinion.id}-vote-button" do
            expect(page).to have_button("Already supported")
            expect(page).to have_no_button("Support")
          end

          within "#opinion-#{opinion.id}-votes-count" do
            expect(page).to have_content("1 Support")
          end
        end

        it "is able to undo the vote" do
          within "#opinion-#{opinion.id}-vote-button" do
            click_button "Already supported"
            expect(page).to have_button("Support")
          end

          within "#opinion-#{opinion.id}-votes-count" do
            expect(page).to have_content("0 Supports")
          end
        end
      end

      context "when the component has a vote limit" do
        let(:vote_limit) { 10 }

        let!(:component) do
          create(:opinion_component,
                 :with_votes_enabled,
                 :with_vote_limit,
                 vote_limit: vote_limit,
                 manifest: manifest,
                 participatory_space: participatory_process)
        end

        describe "vote counter" do
          context "when votes are blocked" do
            let!(:component) do
              create(:opinion_component,
                     :with_votes_blocked,
                     :with_vote_limit,
                     vote_limit: vote_limit,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "doesn't show the remaining votes counter" do
              visit_component

              expect(page).to have_css(".voting-rules")
              expect(page).to have_no_css(".remaining-votes-counter")
            end
          end

          context "when votes are enabled" do
            let!(:component) do
              create(:opinion_component,
                     :with_votes_enabled,
                     :with_vote_limit,
                     vote_limit: vote_limit,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "shows the remaining votes counter" do
              visit_component

              expect(page).to have_css(".voting-rules")
              expect(page).to have_css(".remaining-votes-counter")
            end
          end
        end

        context "when the opinion is not voted yet" do
          before do
            visit_component
          end

          it "updates the remaining votes counter" do
            within "#opinion-#{opinion.id}-vote-button" do
              click_button "Support"
              expect(page).to have_button("Already supported")
            end

            expect(page).to have_content("REMAINING\n9\nSupports")
          end
        end

        context "when the opinion is not voted yet but the user isn't authorized" do
          before do
            permissions = {
              vote: {
                authorization_handlers: {
                  "dummy_authorization_handler" => { "options" => {} }
                }
              }
            }

            component.update!(permissions: permissions)
            visit_component
          end

          it "shows a modal dialog" do
            within "#opinion-#{opinion.id}-vote-button" do
              click_button "Support"
            end

            expect(page).to have_content("Authorization required")
          end
        end

        context "when the opinion is already voted" do
          before do
            create(:opinion_vote, opinion: opinion, author: user)
            visit_component
          end

          it "is not able to vote it again" do
            within "#opinion-#{opinion.id}-vote-button" do
              expect(page).to have_button("Already supported")
              expect(page).to have_no_button("Support")
            end
          end

          it "is able to undo the vote" do
            within "#opinion-#{opinion.id}-vote-button" do
              click_button "Already supported"
              expect(page).to have_button("Support")
            end

            within "#opinion-#{opinion.id}-votes-count" do
              expect(page).to have_content("0 Supports")
            end

            expect(page).to have_content("REMAINING\n10\nSupports")
          end
        end

        context "when the user has reached the votes limit" do
          let(:vote_limit) { 1 }

          before do
            create(:opinion_vote, opinion: opinion, author: user)
            visit_component
          end

          it "is not able to vote other opinions" do
            expect(page).to have_css(".button[disabled]", count: 2)
          end

          context "when votes are blocked" do
            let!(:component) do
              create(:opinion_component,
                     :with_votes_blocked,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "shows the vote count but not the vote button" do
              within "#opinion_#{opinion.id} .card__support" do
                expect(page).to have_content("1 Support")
              end

              expect(page).to have_content("Supports disabled")
            end
          end
        end
      end
    end

    context "when the opinion is rejected", :slow do
      let!(:rejected_opinion) { create(:opinion, :rejected, component: component) }

      before do
        component.update!(settings: { opinion_answering_enabled: true })
      end

      it "cannot be voted" do
        visit_component

        within ".filters .state_check_boxes_tree_filter" do
          check "All"
          uncheck "All"
          check "Rejected"
        end

        page.find_link rejected_opinion.title
        expect(page).to have_no_selector("#opinion-#{rejected_opinion.id}-vote-button")

        click_link rejected_opinion.title
        expect(page).to have_no_selector("#opinion-#{rejected_opinion.id}-vote-button")
      end
    end

    context "when opinions have a voting limit" do
      let!(:component) do
        create(:opinion_component,
               :with_votes_enabled,
               :with_threshold_per_opinion,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      before do
        login_as user, scope: :user
      end

      it "doesn't allow users to vote to a opinion that's reached the limit" do
        create(:opinion_vote, opinion: opinion)
        visit_component

        opinion_element = page.find(".card--opinion", text: opinion.title)

        within opinion_element do
          within ".card__support", match: :first do
            expect(page).to have_content("Support limit reached")
          end
        end
      end

      it "allows users to vote on opinions under the limit" do
        visit_component

        opinion_element = page.find(".card--opinion", text: opinion.title)

        within opinion_element do
          within ".card__support", match: :first do
            click_button "Support"
            expect(page).to have_content("Already supported")
          end
        end
      end
    end

    context "when opinions have vote limit but can accumulate more votes" do
      let!(:component) do
        create(:opinion_component,
               :with_votes_enabled,
               :with_threshold_per_opinion,
               :with_can_accumulate_supports_beyond_threshold,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      before do
        login_as user, scope: :user
      end

      it "allows users to vote on opinions over the limit" do
        create(:opinion_vote, opinion: opinion)
        visit_component

        opinion_element = page.find(".card--opinion", text: opinion.title)

        within opinion_element do
          within ".card__support", match: :first do
            expect(page).to have_content("1 Support")
          end
        end
      end
    end

    context "when opinions have a minimum amount of votes" do
      let!(:component) do
        create(:opinion_component,
               :with_votes_enabled,
               :with_minimum_votes_per_user,
               minimum_votes_per_user: 3,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      before do
        login_as user, scope: :user
      end

      it "doesn't count votes unless the minimum is achieved" do
        visit_component

        opinion_elements = opinions.map do |opinion|
          page.find(".card--opinion", text: opinion.title)
        end

        within opinion_elements[0] do
          click_button "Support"
          expect(page).to have_content("Already supported")
          expect(page).to have_content("0 Supports")
        end

        within opinion_elements[1] do
          click_button "Support"
          expect(page).to have_content("Already supported")
          expect(page).to have_content("0 Supports")
        end

        within opinion_elements[2] do
          click_button "Support"
          expect(page).to have_content("Already supported")
          expect(page).to have_content("1 Support")
        end

        within opinion_elements[0] do
          expect(page).to have_content("1 Support")
        end

        within opinion_elements[1] do
          expect(page).to have_content("1 Support")
        end
      end
    end

    describe "gamification" do
      before do
        login_as user, scope: :user
      end

      it "gives a point after voting" do
        visit_component

        opinion_element = page.find(".card--opinion", text: opinion.title)

        expect do
          within opinion_element do
            within ".card__support", match: :first do
              click_button "Support"
              expect(page).to have_content("1 Support")
            end
          end
        end.to change { Decidim::Gamification.status_for(user, :opinion_votes).score }.by(1)
      end
    end
  end
end
