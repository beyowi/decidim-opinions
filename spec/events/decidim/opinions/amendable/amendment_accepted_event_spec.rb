# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Amendable
    describe AmendmentAcceptedEvent do
      let!(:component) { create(:opinion_component) }
      let!(:amendable) { create(:opinion, component: component, title: "My super opinion") }
      let!(:emendation) { create(:opinion, component: component, title: "My super emendation") }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation }

      include_examples "amendment accepted event"
    end
  end
end