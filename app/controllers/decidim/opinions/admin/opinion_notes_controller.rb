# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # This controller allows admins to make private notes on opinions in a participatory process.
      class OpinionNotesController < Admin::ApplicationController
        helper_method :opinion

        def create
          enforce_permission_to :create, :opinion_note, opinion: opinion
          @form = form(OpinionNoteForm).from_params(params)

          CreateOpinionNote.call(@form, opinion) do
            on(:ok) do
              flash[:notice] = I18n.t("opinion_notes.create.success", scope: "decidim.opinions.admin")
              redirect_to opinion_path(id: opinion.id)
            end

            on(:invalid) do
              flash.keep[:alert] = I18n.t("opinion_notes.create.error", scope: "decidim.opinions.admin")
              redirect_to opinion_path(id: opinion.id)
            end
          end
        end

        private

        def skip_manage_component_permission
          true
        end

        def opinion
          @opinion ||= Opinion.where(component: current_component).find(params[:opinion_id])
        end
      end
    end
  end
end
