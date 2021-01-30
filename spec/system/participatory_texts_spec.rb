# frozen_string_literal: true

require "spec_helper"

describe "Participatory texts", type: :system do
  include Decidim::SanitizeHelper
  include ActionView::Helpers::TextHelper

  include_context "with a component"
  let(:manifest_name) { "opinions" }

  def update_step_settings(new_step_settings)
    active_step_id = participatory_process.active_step.id.to_s
    step_settings = component.step_settings[active_step_id].to_h.merge(new_step_settings)
    component.update!(
      settings: component.settings.to_h.merge(amendments_enabled: true),
      step_settings: { active_step_id => step_settings }
    )
  end

  def should_have_opinion(selector, opinion)
    expect(page).to have_tag(selector, text: opinion.title)
    prop_block = page.find(selector)
    prop_block.hover
    clean_opinion_body = strip_tags(opinion.body)

    expect(prop_block).to have_button("Follow")
    expect(prop_block).to have_link("Comment") if component.settings.comments_enabled
    expect(prop_block).to have_link(opinion.comments.count.to_s) if component.settings.comments_enabled
    expect(prop_block).to have_content(clean_opinion_body) if opinion.participatory_text_level == "article"
    expect(prop_block).not_to have_content(clean_opinion_body) if opinion.participatory_text_level != "article"
  end

  shared_examples_for "lists all the opinions ordered" do
    it "by position" do
      visit_component
      expect(page).to have_css(".hover-section", count: opinions.count)
      opinions.each_with_index do |opinion, index|
        should_have_opinion("#opinions div.hover-section:nth-child(#{index + 1})", opinion)
      end
    end

    context " when participatory text level is not article" do
      it "not renders the participatory text body" do
        opinion_section = opinions.first
        opinion_section.participatory_text_level = "section"
        opinion_section.save!
        visit_component
        should_have_opinion("#opinions div.hover-section:first-child", opinion_section)
      end
    end

    context "when participatory text level is article" do
      it "renders the opinion body" do
        opinion_article = opinions.last
        opinion_article.participatory_text_level = "article"
        opinion_article.save!
        visit_component
        should_have_opinion("#opinions div.hover-section:last-child", opinion_article)
      end
    end
  end

  shared_examples "showing the Amend buttton and amendments counter when hovered" do
    let(:amend_button_disabled?) { page.find("a", text: "AMEND")[:disabled].present? }

    it "shows the Amend buttton and amendments counter inside the opinion div" do
      visit_component
      find("#opinions div.hover-section", text: opinions.first.title).hover
      within all("#opinions div.hover-section").first, visible: true do
        within ".amend-buttons" do
          expect(page).to have_link("Amend")
          expect(amend_button_disabled?).to eq(disabled_value)
          expect(page).to have_link(amendments_count)
        end
      end
    end
  end

  shared_examples "hiding the Amend buttton and amendments counter when hovered" do
    it "hides the Amend buttton and amendments counter inside the opinion div" do
      visit_component
      find("#opinions div.hover-section", text: opinions.first.title).hover
      within all("#opinions div.hover-section").first, visible: true do
        expect(page).not_to have_css(".amend-buttons")
      end
    end
  end

  context "when listing opinions in a participatory process as participatory texts" do
    context "when admin has not yet published a participatory text" do
      let!(:component) do
        create(:opinion_component,
               :with_participatory_texts_enabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      before do
        visit_component
      end

      it "renders an alternative title" do
        expect(page).to have_content("There are no participatory texts at the moment")
      end
    end

    context "when admin has published a participatory text" do
      let!(:participatory_text) { create :participatory_text, component: component }
      let!(:opinions) { create_list(:opinion, 3, :published, component: component) }
      let!(:component) do
        create(:opinion_component,
               :with_participatory_texts_enabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      it_behaves_like "lists all the opinions ordered"

      it "renders the participatory text title" do
        visit_component

        expect(page).to have_content(participatory_text.title)
      end

      context "without existing amendments" do
        context "when amendment CREATION is enabled" do
          before { update_step_settings(amendment_creation_enabled: true) }

          it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
            let(:amendments_count) { 0 }
            let(:disabled_value) { false }
          end
        end

        context "when amendment CREATION is disabled" do
          before { update_step_settings(amendment_creation_enabled: false) }

          it_behaves_like "hiding the Amend buttton and amendments counter when hovered"
        end
      end

      context "with existing amendments" do
        let!(:emendation_1) { create(:opinion, :published, component: component) }
        let!(:amendment_1) { create :amendment, amendable: opinions.first, emendation: emendation_1 }
        let!(:emendation_2) { create(:opinion, component: component) }
        let!(:amendment_2) { create(:amendment, amendable: opinions.first, emendation: emendation_2) }
        let(:user) { amendment_1.amender }

        context "when amendment CREATION is enabled" do
          before { update_step_settings(amendment_creation_enabled: true) }

          context "and amendments VISIBILITY is set to 'all'" do
            before { update_step_settings(amendments_visibility: "all") }

            context "when the user is logged in" do
              before { login_as user, scope: :user }

              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 2 }
                let(:disabled_value) { false }
              end
            end

            context "when the user is NOT logged in" do
              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 2 }
                let(:disabled_value) { false }
              end
            end
          end

          context "and amendments VISIBILITY is set to 'participants'" do
            before { update_step_settings(amendments_visibility: "participants") }

            context "when the user is logged in" do
              before { login_as user, scope: :user }

              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 1 }
                let(:disabled_value) { false }
              end
            end

            context "when the user is NOT logged in" do
              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 0 }
                let(:disabled_value) { false }
              end
            end
          end
        end

        context "when amendment CREATION is disabled" do
          before { update_step_settings(amendment_creation_enabled: false) }

          context "and amendments VISIBILITY is set to 'all'" do
            before { update_step_settings(amendments_visibility: "all") }

            context "when the user is logged in" do
              let(:user) { amendment_1.amender }

              before { login_as user, scope: :user }

              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 2 }
                let(:disabled_value) { true }
              end
            end

            context "when the user is NOT logged in" do
              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 2 }
                let(:disabled_value) { true }
              end
            end
          end

          context "and amendments VISIBILITY is set to 'participants'" do
            before { update_step_settings(amendments_visibility: "participants") }

            context "when the user is logged in" do
              let(:user) { amendment_1.amender }

              before { login_as user, scope: :user }

              it_behaves_like "showing the Amend buttton and amendments counter when hovered" do
                let(:amendments_count) { 1 }
                let(:disabled_value) { true }
              end
            end

            context "when the user is NOT logged in" do
              it_behaves_like "hiding the Amend buttton and amendments counter when hovered"
            end
          end
        end
      end

      context "when comments are enabled" do
        let!(:component) do
          create(:opinion_component,
                 :with_participatory_texts_enabled,
                 :with_votes_enabled,
                 manifest: manifest,
                 participatory_space: participatory_process)
        end

        it_behaves_like "lists all the opinions ordered"
      end

      context "when comments are disabled" do
        let(:component) do
          create(:opinion_component,
                 :with_comments_disabled,
                 :with_participatory_texts_enabled,
                 manifest: manifest,
                 participatory_space: participatory_process)
        end

        it_behaves_like "lists all the opinions ordered"
      end
    end
  end
end
