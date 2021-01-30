# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Amendable
    describe EmendationPromotedEvent do
      let!(:component) { create(:opinion_component) }
      let!(:amendable) { create(:opinion, component: component, title: "My super opinion") }
      let!(:emendation) { create(:opinion, component: component, title: "My super emendation") }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation }
      let(:amendable_type) { "opinion" }

      include_examples "amendment promoted event"
    end
  end
end
