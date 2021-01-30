# frozen_string_literal: true

require "spec_helper"

describe "Opinions", type: :system do
  include_context "with a component"
  let(:manifest_name) { "opinions" }
  let!(:user) { create :user, :confirmed, organization: organization }
  let!(:component) do
    create(:opinion_component,
           :with_creation_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end

  before do
    login_as user, scope: :user
  end

  context "when creating a new opinion" do
    before do
      login_as user, scope: :user
      visit_component
    end

    context "and draft opinion exists for current users" do
      let!(:draft) { create(:opinion, :draft, component: component, users: [user]) }

      it "redirects to edit draft" do
        click_link "New opinion"
        path = "#{main_component_path(component)}opinions/#{draft.id}/edit_draft?component_id=#{component.id}&question_slug=#{component.participatory_space.slug}"
        expect(page).to have_current_path(path)
      end
    end

    context "when rich text editor is enabled for participants" do
      before do
        organization.update(rich_text_editor_in_public_views: true)
        click_link "New opinion"
      end

      it_behaves_like "having a rich text editor", "new_opinion", "basic"

      it "has helper character counter" do
        within "form.new_opinion" do
          expect(find(".editor").sibling(".form-input-extra-before")).to have_content("at least 15 characters", count: 1)
        end
      end
    end
  end
end
