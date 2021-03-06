# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Amendable
    describe AmendmentCreatedEvent do
      let!(:component) { create(:opinion_component) }
      let!(:amendable) { create(:opinion, component: component, title: "My super opinion") }
      let!(:emendation) { create(:opinion, component: component, title: "My super emendation") }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation }

      include_examples "amendment created event"
    end
  end
end
