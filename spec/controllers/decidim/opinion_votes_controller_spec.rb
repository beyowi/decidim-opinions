# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe OpinionVotesController, type: :controller do
      routes { Decidim::Opinions::Engine.routes }

      let(:opinion) { create(:opinion, component: component) }
      let(:user) { create(:user, :confirmed, organization: component.organization) }

      let(:params) do
        {
          opinion_id: opinion.id,
          component_id: component.id
        }
      end

      before do
        request.env["decidim.current_organization"] = component.organization
        request.env["decidim.current_participatory_space"] = component.participatory_space
        request.env["decidim.current_component"] = component
        sign_in user
      end

      describe "POST create" do
        context "with votes enabled" do
          let(:component) do
            create(:opinion_component, :with_votes_enabled)
          end

          it "allows voting" do
            expect do
              post :create, format: :js, params: params
            end.to change(OpinionVote, :count).by(1)

            expect(OpinionVote.last.author).to eq(user)
            expect(OpinionVote.last.opinion).to eq(opinion)
          end
        end

        context "with votes disabled" do
          let(:component) do
            create(:opinion_component)
          end

          it "doesn't allow voting" do
            expect do
              post :create, format: :js, params: params
            end.not_to change(OpinionVote, :count)

            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end

        context "with votes enabled but votes blocked" do
          let(:component) do
            create(:opinion_component, :with_votes_blocked)
          end

          it "doesn't allow voting" do
            expect do
              post :create, format: :js, params: params
            end.not_to change(OpinionVote, :count)

            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end
      end

      describe "destroy" do
        before do
          create(:opinion_vote, opinion: opinion, author: user)
        end

        context "with vote limit enabled" do
          let(:component) do
            create(:opinion_component, :with_votes_enabled, :with_vote_limit)
          end

          it "deletes the vote" do
            expect do
              delete :destroy, format: :js, params: params
            end.to change(OpinionVote, :count).by(-1)

            expect(OpinionVote.count).to eq(0)
          end
        end

        context "with vote limit disabled" do
          let(:component) do
            create(:opinion_component, :with_votes_enabled)
          end

          it "deletes the vote" do
            expect do
              delete :destroy, format: :js, params: params
            end.to change(OpinionVote, :count).by(-1)

            expect(OpinionVote.count).to eq(0)
          end
        end
      end
    end
  end
end
