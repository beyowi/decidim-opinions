# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Opinions
    # This cell renders the linked resource of a opinion.
    class OpinionLinkedResourcesCell < Decidim::ViewModel
      def show
        render if linked_resource
      end
    end
  end
end
