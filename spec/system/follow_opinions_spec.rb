# frozen_string_literal: true

require "spec_helper"

describe "Follow opinions", type: :system do
  let(:manifest_name) { "opinions" }

  let!(:followable) do
    create(:opinion, component: component)
  end

  include_examples "follows"
end
