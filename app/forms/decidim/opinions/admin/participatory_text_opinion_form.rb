# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A form object to be used when admin users want to create a opinion
      # through the participatory texts.
      class ParticipatoryTextOpinionForm < Admin::OpinionBaseForm
        validates :title, length: { maximum: 150 }
      end
    end
  end
end
