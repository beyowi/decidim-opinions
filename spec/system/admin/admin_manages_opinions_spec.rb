# frozen_string_literal: true

require "spec_helper"

describe "Admin manages opinions", type: :system do
  let(:manifest_name) { "opinions" }
  let!(:opinion) { create :opinion, component: current_component }
  let!(:reportables) { create_list(:opinion, 3, component: current_component) }
  let(:participatory_space_path) do
    decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
  end

  include_context "when managing a component as an admin"

  it_behaves_like "manage opinions"
  it_behaves_like "view opinion details from admin"
  it_behaves_like "manage moderations"
  it_behaves_like "export opinions"
  it_behaves_like "manage announcements"
  it_behaves_like "manage opinions help texts"
  it_behaves_like "manage opinion wizard steps help texts"
  it_behaves_like "when managing opinions category as an admin"
  it_behaves_like "when managing opinions scope as an admin"
  it_behaves_like "import opinions"
  it_behaves_like "manage opinions permissions"
  it_behaves_like "merge opinions"
  it_behaves_like "split opinions"
  it_behaves_like "filter opinions"
  it_behaves_like "publish answers"
end
