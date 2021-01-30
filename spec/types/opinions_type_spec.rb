# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"
require "decidim/core/test"

module Decidim
  module Opinions
    describe OpinionsType, type: :graphql do
      include_context "with a graphql type"
      let(:model) { create(:opinion_component) }

      it_behaves_like "a component query type"

      describe "opinions" do
        let!(:draft_opinions) { create_list(:opinion, 2, :draft, component: model) }
        let!(:published_opinions) { create_list(:opinion, 2, component: model) }
        let!(:other_opinions) { create_list(:opinion, 2) }

        let(:query) { "{ opinions { edges { node { id } } } }" }

        it "returns the published opinions" do
          ids = response["opinions"]["edges"].map { |edge| edge["node"]["id"] }
          expect(ids).to include(*published_opinions.map(&:id).map(&:to_s))
          expect(ids).not_to include(*draft_opinions.map(&:id).map(&:to_s))
          expect(ids).not_to include(*other_opinions.map(&:id).map(&:to_s))
        end
      end

      describe "opinion" do
        let(:query) { "query Opinion($id: ID!){ opinion(id: $id) { id } }" }
        let(:variables) { { id: opinion.id.to_s } }

        context "when the opinion belongs to the component" do
          let!(:opinion) { create(:opinion, component: model) }

          it "finds the opinion" do
            expect(response["opinion"]["id"]).to eq(opinion.id.to_s)
          end
        end

        context "when the opinion doesn't belong to the component" do
          let!(:opinion) { create(:opinion, component: create(:opinion_component)) }

          it "returns null" do
            expect(response["opinion"]).to be_nil
          end
        end

        context "when the opinion is not published" do
          let!(:opinion) { create(:opinion, :draft, component: model) }

          it "returns null" do
            expect(response["opinion"]).to be_nil
          end
        end
      end
    end
  end
end
