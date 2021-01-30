# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A form object to be used when admin users want to review a collection of opinions
      # from a participatory text.
      class PreviewParticipatoryTextForm < Decidim::Form
        attribute :opinions, Array[Decidim::Opinions::Admin::ParticipatoryTextOpinionForm]

        def from_models(opinions)
          self.opinions = opinions.collect do |opinion|
            Admin::ParticipatoryTextOpinionForm.from_model(opinion)
          end
        end

        def opinions_attributes=(attributes); end
      end
    end
  end
end
