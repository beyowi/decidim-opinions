# frozen_string_literal: true

require "spec_helper"

describe "Report Opinion", type: :system do
  include_context "with a component"

  let(:manifest_name) { "opinions" }
  let!(:opinions) { create_list(:opinion, 3, component: component) }
  let(:reportable) { opinions.first }
  let(:reportable_path) { resource_locator(reportable).path }
  let!(:user) { create :user, :confirmed, organization: organization }

  let!(:component) do
    create(:opinion_component,
           manifest: manifest,
           participatory_space: participatory_process)
  end

  include_examples "reports"
end
