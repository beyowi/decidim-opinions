# frozen_string_literal: true

require "spec_helper"

describe "Show a Opinion", type: :system do
  include_context "with a component"
  let(:manifest_name) { "opinions" }
  let(:opinion) { create :opinion, component: component }

  def visit_opinion
    visit resource_locator(opinion).path
  end

  describe "opinion show" do
    it_behaves_like "editable content for admins" do
      let(:target_path) { resource_locator(opinion).path }
    end

    context "when requesting the opinion path" do
      before do
        visit_opinion
      end

      describe "extra admin link" do
        before do
          login_as user, scope: :user
          visit current_path
        end

        context "when I'm an admin user" do
          let(:user) { create(:user, :admin, :confirmed, organization: organization) }

          it "has a link to answer to the opinion at the admin" do
            within ".topbar" do
              expect(page).to have_link("Answer", href: /.*admin.*opinion-answer.*/)
            end
          end
        end

        context "when I'm a regular user" do
          let(:user) { create(:user, :confirmed, organization: organization) }

          it "does not have a link to answer the opinion at the admin" do
            within ".topbar" do
              expect(page).not_to have_link("Answer")
            end
          end
        end
      end
    end
  end
end
