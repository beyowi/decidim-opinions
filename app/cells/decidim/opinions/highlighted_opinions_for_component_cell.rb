# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Opinions
    # This cell renders the highlighted opinions for a given component.
    # It is intended to be used in the `participatory_space_highlighted_elements`
    # view hook.
    class HighlightedOpinionsForComponentCell < Decidim::ViewModel
      include Decidim::ComponentPathHelper

      def show
        render unless opinions_count.zero?
      end

      private

      def opinions
        @opinions ||= Decidim::Opinions::Opinion.published.not_hidden.except_withdrawn
                                                   .where(component: model)
                                                   .order_randomly(rand * 2 - 1)
      end

      def opinions_to_render
        @opinions_to_render ||= opinions.includes([:amendable, :category, :component, :scope]).limit(Decidim::Opinions.config.participatory_space_highlighted_opinions_limit)
      end

      def opinions_count
        @opinions_count ||= opinions.count
      end
    end
  end
end
