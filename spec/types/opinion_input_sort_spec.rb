# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"
require "decidim/core/test"
require "decidim/core/test/shared_examples/input_sort_examples"

module Decidim
  module Opinions
    describe OpinionInputSort, type: :graphql do
      include_context "with a graphql type"

      let(:type_class) { Decidim::Opinions::OpinionsType }

      let(:model) { create(:opinion_component) }
      let!(:models) { create_list(:opinion, 3, :published, component: model) }

      context "when sorting by opinions id" do
        include_examples "connection has input sort", "opinions", "id"
      end

      context "when sorting by published_at" do
        include_examples "connection has input sort", "opinions", "publishedAt"
      end

      context "when sorting by endorsement_count" do
        let!(:most_endorsed) { create(:opinion, :published, :with_endorsements, component: model) }

        include_examples "connection has endorsement_count sort", "opinions"
      end

      context "when sorting by vote_count" do
        let!(:votes) { create_list(:opinion_vote, 3, opinion: models.last) }

        describe "ASC" do
          let(:query) { %[{ opinions(order: {voteCount: "ASC"}) { edges { node { id } } } }] }

          it "returns the most voted last" do
            expect(response["opinions"]["edges"].count).to eq(3)
            expect(response["opinions"]["edges"].last["node"]["id"]).to eq(models.last.id.to_s)
          end
        end

        describe "DESC" do
          let(:query) { %[{ opinions(order: {voteCount: "DESC"}) { edges { node { id } } } }] }

          it "returns the most voted first" do
            expect(response["opinions"]["edges"].count).to eq(3)
            expect(response["opinions"]["edges"].first["node"]["id"]).to eq(models.last.id.to_s)
          end
        end
      end
    end
  end
end
