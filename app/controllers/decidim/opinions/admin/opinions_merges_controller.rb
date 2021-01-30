# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      class OpinionsMergesController < Admin::ApplicationController
        def create
          enforce_permission_to :merge, :opinions

          @form = form(Admin::OpinionsMergeForm).from_params(params)

          Admin::MergeOpinions.call(@form) do
            on(:ok) do |_opinion|
              flash[:notice] = I18n.t("opinions_merges.create.success", scope: "decidim.opinions.admin")
              redirect_to EngineRouter.admin_proxy(@form.target_component).root_path
            end

            on(:invalid) do
              flash[:alert] = I18n.t("opinions_merges.create.invalid", scope: "decidim.opinions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end
      end
    end
  end
end
