# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"
require "decidim/core/test"
require "decidim/core/test/shared_examples/input_filter_examples"

module Decidim
  module Opinions
    describe OpinionInputFilter, type: :graphql do
      include_context "with a graphql type"
      let(:type_class) { Decidim::Opinions::OpinionsType }

      let(:model) { create(:opinion_component) }
      let!(:models) { create_list(:opinion, 3, :published, component: model) }

      context "when filtered by published_at" do
        include_examples "connection has before/since input filter", "opinions", "published"
      end
    end
  end
end
