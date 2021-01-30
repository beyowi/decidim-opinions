# frozen_string_literal: true

require "spec_helper"

describe "Search opinions", type: :system do
  include_context "with a component"
  let(:manifest_name) { "opinions" }
  let!(:searchables) { create_list(:opinion, 3, component: component) }
  let!(:term) { searchables.first.title.split(" ").last }

  before do
    searchables.each { |s| s.update(published_at: Time.current) }
  end

  include_examples "searchable results"
end
