# frozen_string_literal: true

module Decidim
  module Opinions
    # Exposes Opinions versions so users can see how a Opinion/CollaborativeDraft
    # has been updated through time.
    class VersionsController < Decidim::Opinions::ApplicationController
      include Decidim::ApplicationHelper
      include Decidim::ResourceVersionsConcern

      def versioned_resource
        @versioned_resource ||=
          if params[:opinion_id]
            present(Opinion.where(component: current_component).find(params[:opinion_id]))
          else
            CollaborativeDraft.where(component: current_component).find(params[:collaborative_draft_id])
          end
      end
    end
  end
end
