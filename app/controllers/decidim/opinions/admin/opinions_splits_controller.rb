# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      class OpinionsSplitsController < Admin::ApplicationController
        def create
          enforce_permission_to :split, :opinions

          @form = form(Admin::OpinionsSplitForm).from_params(params)

          Admin::SplitOpinions.call(@form) do
            on(:ok) do |_opinion|
              flash[:notice] = I18n.t("opinions_splits.create.success", scope: "decidim.opinions.admin")
              redirect_to EngineRouter.admin_proxy(@form.target_component).root_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("opinions_splits.create.invalid", scope: "decidim.opinions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end
      end
    end
  end
end
