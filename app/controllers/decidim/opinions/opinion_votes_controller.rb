# frozen_string_literal: true

module Decidim
  module Opinions
    # Exposes the opinion vote resource so users can vote opinions.
    class OpinionVotesController < Decidim::Opinions::ApplicationController
      include OpinionVotesHelper
      include Rectify::ControllerHelpers

      helper_method :opinion

      before_action :authenticate_user!

      def create
        enforce_permission_to :vote, :opinion, opinion: opinion
        @from_opinions_list = params[:from_opinions_list] == "true"

        VoteOpinion.call(opinion, current_user) do
          on(:ok) do
            opinion.reload

            opinions = OpinionVote.where(
              author: current_user,
              opinion: Opinion.where(component: current_component)
            ).map(&:opinion)

            expose(opinions: opinions)
            render :update_buttons_and_counters
          end

          on(:invalid) do
            render json: { error: I18n.t("opinion_votes.create.error", scope: "decidim.opinions") }, status: :unprocessable_entity
          end
        end
      end

      def destroy
        enforce_permission_to :unvote, :opinion, opinion: opinion
        @from_opinions_list = params[:from_opinions_list] == "true"

        UnvoteOpinion.call(opinion, current_user) do
          on(:ok) do
            opinion.reload

            opinions = OpinionVote.where(
              author: current_user,
              opinion: Opinion.where(component: current_component)
            ).map(&:opinion)

            expose(opinions: opinions + [opinion])
            render :update_buttons_and_counters
          end
        end
      end

      private

      def opinion
        @opinion ||= Opinion.where(component: current_component).find(params[:opinion_id])
      end
    end
  end
end
