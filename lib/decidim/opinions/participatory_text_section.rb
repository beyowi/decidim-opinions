# frozen_string_literal: true

module Decidim
  module Opinions
    # The data store for a Opinion in the Decidim::Opinions component.
    module ParticipatoryTextSection
      extend ActiveSupport::Concern

      LEVELS = {
        section: "section", sub_section: "sub-section", article: "article"
      }.freeze

      included do
        # Public: is this section an :article?
        def article?
          participatory_text_level == LEVELS[:article]
        end
      end
    end
  end
end
