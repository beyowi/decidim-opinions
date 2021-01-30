# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # This controller allows admins to answer opinions in a participatory process.
      class OpinionAnswersController < Admin::ApplicationController
        helper_method :opinion

        helper Opinions::ApplicationHelper
        helper Decidim::Opinions::Admin::OpinionsHelper
        helper Decidim::Opinions::Admin::OpinionRankingsHelper
        helper Decidim::Messaging::ConversationHelper

        def edit
          enforce_permission_to :create, :opinion_answer, opinion: opinion
          @form = form(Admin::OpinionAnswerForm).from_model(opinion)
        end

        def update
          enforce_permission_to :create, :opinion_answer, opinion: opinion
          @notes_form = form(OpinionNoteForm).instance
          @answer_form = form(Admin::OpinionAnswerForm).from_params(params)

          Admin::AnswerOpinion.call(@answer_form, opinion) do
            on(:ok) do
              flash[:notice] = I18n.t("opinions.answer.success", scope: "decidim.opinions.admin")
              redirect_to opinions_path
            end

            on(:invalid) do
              flash.keep[:alert] = I18n.t("opinions.answer.invalid", scope: "decidim.opinions.admin")
              render template: "decidim/opinions/admin/opinions/show"
            end
          end
        end

        private

        def skip_manage_component_permission
          true
        end

        def opinion
          @opinion ||= Opinion.where(component: current_component).find(params[:id])
        end
      end
    end
  end
end
