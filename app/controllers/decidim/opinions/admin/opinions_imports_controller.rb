# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      class OpinionsImportsController < Admin::ApplicationController
        def new
          enforce_permission_to :import, :opinions

          @form = form(Admin::OpinionsImportForm).instance
        end

        def create
          enforce_permission_to :import, :opinions

          @form = form(Admin::OpinionsImportForm).from_params(params)

          Admin::ImportOpinions.call(@form) do
            on(:ok) do |opinions|
              flash[:notice] = I18n.t("opinions_imports.create.success", scope: "decidim.opinions.admin", number: opinions.length)
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("opinions_imports.create.invalid", scope: "decidim.opinions.admin")
              render action: "new"
            end
          end
        end
      end
    end
  end
end
