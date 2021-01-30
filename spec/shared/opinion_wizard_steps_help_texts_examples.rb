# frozen_string_literal: true

shared_examples "manage opinion wizard steps help texts" do
  before do
    current_component.update!(
      step_settings: {
        current_component.participatory_space.active_step.id => {
          creation_enabled: true
        }
      }
    )
  end

  let!(:opinion) { create(:opinion, component: current_component) }
  let!(:opinion_similar) { create(:opinion, component: current_component, title: "This opinion is to ensure a similar exists") }
  let!(:opinion_draft) { create(:opinion, :draft, component: current_component, title: "This opinion has a similar") }

  it "customize the help text for step 1 of the opinion wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_opinion_wizard_step_1_help_text,
      "#global-settings-opinion_wizard_step_1_help_text-tabs",
      en: "This is the first step of the Opinion creation wizard.",
      es: "Este es el primer paso del asistente de creación de propuestas.",
      ca: "Aquest és el primer pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    visit new_opinion_path(current_component)
    within ".opinion_wizard_help_text" do
      expect(page).to have_content("This is the first step of the Opinion creation wizard.")
    end
  end

  it "customize the help text for step 2 of the opinion wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_opinion_wizard_step_2_help_text,
      "#global-settings-opinion_wizard_step_2_help_text-tabs",
      en: "This is the second step of the Opinion creation wizard.",
      es: "Este es el segundo paso del asistente de creación de propuestas.",
      ca: "Aquest és el segon pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    create(:opinion, title: "More sidewalks and less roads", body: "Cities need more people, not more cars", component: component)
    create(:opinion, title: "More trees and parks", body: "Green is always better", component: component)
    visit_component
    click_link "New opinion"
    within ".new_opinion" do
      fill_in :opinion_title, with: "More sidewalks and less roads"
      fill_in :opinion_body, with: "Cities need more people, not more cars"

      find("*[type=submit]").click
    end

    within ".opinion_wizard_help_text" do
      expect(page).to have_content("This is the second step of the Opinion creation wizard.")
    end
  end

  it "customize the help text for step 3 of the opinion wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_opinion_wizard_step_3_help_text,
      "#global-settings-opinion_wizard_step_3_help_text-tabs",
      en: "This is the third step of the Opinion creation wizard.",
      es: "Este es el tercer paso del asistente de creación de propuestas.",
      ca: "Aquest és el tercer pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    visit_component
    click_link "New opinion"
    within ".new_opinion" do
      fill_in :opinion_title, with: "More sidewalks and less roads"
      fill_in :opinion_body, with: "Cities need more people, not more cars"

      find("*[type=submit]").click
    end

    within ".opinion_wizard_help_text" do
      expect(page).to have_content("This is the third step of the Opinion creation wizard.")
    end
  end

  it "customize the help text for step 4 of the opinion wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_opinion_wizard_step_4_help_text,
      "#global-settings-opinion_wizard_step_4_help_text-tabs",
      en: "This is the fourth step of the Opinion creation wizard.",
      es: "Este es el cuarto paso del asistente de creación de propuestas.",
      ca: "Aquest és el quart pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    visit preview_opinion_path(current_component, opinion_draft)
    within ".opinion_wizard_help_text" do
      expect(page).to have_content("This is the fourth step of the Opinion creation wizard.")
    end
  end

  private

  def new_opinion_path(current_component)
    Decidim::EngineRouter.main_proxy(current_component).new_opinion_path(current_component.id)
  end

  def complete_opinion_path(current_component, opinion)
    Decidim::EngineRouter.main_proxy(current_component).complete_opinion_path(opinion)
  end

  def preview_opinion_path(current_component, opinion)
    Decidim::EngineRouter.main_proxy(current_component).opinion_path(opinion) + "/preview"
  end
end
