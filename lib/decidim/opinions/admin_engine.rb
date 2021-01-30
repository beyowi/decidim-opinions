# frozen_string_literal: true

module Decidim
  module Opinions
    # This is the engine that runs on the public interface of `decidim-opinions`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Opinions::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :opinions, only: [:show, :index, :new, :create, :edit, :update] do
          resources :valuation_assignments, only: [:destroy]
          collection do
            post :update_category
            post :publish_answers
            post :update_scope
            resource :opinions_import, only: [:new, :create]
            resource :opinions_merge, only: [:create]
            resource :opinions_split, only: [:create]
            resource :valuation_assignment, only: [:create, :destroy]
          end
          resources :opinion_answers, only: [:edit, :update]
          resources :opinion_notes, only: [:create]
        end

        resources :participatory_texts, only: [:index] do
          collection do
            get :new_import
            post :import
            patch :import
            post :update
            post :discard
          end
        end

        root to: "opinions#index"
      end

      initializer "decidim_opinions.admin_assets" do |app|
        app.config.assets.precompile += %w(admin/decidim_opinions_manifest.js)
      end

      def load_seed
        nil
      end
    end
  end
end
