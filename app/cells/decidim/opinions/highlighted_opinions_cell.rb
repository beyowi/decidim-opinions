# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Opinions
    # This cell renders the highlighted opinions for a given participatory
    # space. It is intended to be used in the `participatory_space_highlighted_elements`
    # view hook.
    class HighlightedOpinionsCell < Decidim::ViewModel
      include OpinionCellsHelper

      private

      def published_components
        Decidim::Component
          .where(
            participatory_space: model,
            manifest_name: :opinions
          )
          .published
      end
    end
  end
end
