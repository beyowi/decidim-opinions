# frozen_string_literal: true

require "spec_helper"

describe "Fingerprint opinion", type: :system do
  let(:manifest_name) { "opinions" }

  let!(:fingerprintable) do
    create(:opinion, component: component)
  end

  include_examples "fingerprint"
end
