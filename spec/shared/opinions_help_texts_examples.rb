# frozen_string_literal: true

shared_examples "manage opinions help texts" do
  before do
    current_component.update!(
      step_settings: {
        current_component.participatory_space.active_step.id => {
          creation_enabled: true
        }
      }
    )
  end

  it "customize a help text for the new opinion page" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_new_opinion_help_text,
      "#global-settings-new_opinion_help_text-tabs",
      en: "Create a opinion following our guidelines.",
      es: "Crea una propuesta siguiendo nuestra guía de estilo.",
      ca: "Crea una proposta seguint la nostra guia d'estil."
    )

    click_button "Update"

    visit new_opinion_path(current_component)

    within ".callout.secondary" do
      expect(page).to have_content("Create a opinion following our guidelines.")
    end
  end

  private

  def new_opinion_path(component)
    Decidim::EngineRouter.main_proxy(component).new_opinion_path(current_component.id)
  end
end
