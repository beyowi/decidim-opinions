# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A form object to be used when admin users want to create a opinion.
      class OpinionForm < Admin::OpinionBaseForm
        validates :title, length: { in: 15..150 }
      end
    end
  end
end
