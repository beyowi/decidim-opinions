# frozen_string_literal: true

module Decidim
  module Opinions
    module Log
      class ValuationAssignmentPresenter < Decidim::Log::ResourcePresenter
        private

        # Private: Presents resource name.
        #
        # Returns an HTML-safe String.
        def present_resource_name
          if resource.present?
            Decidim::Opinions::OpinionPresenter.new(resource.opinion).title
          else
            super
          end
        end
      end
    end
  end
end
