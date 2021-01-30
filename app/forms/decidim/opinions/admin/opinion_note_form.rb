# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A form object to be used when admin users want to create a opinion.
      class OpinionNoteForm < Decidim::Form
        mimic :opinion_note

        attribute :body, String

        validates :body, presence: true
      end
    end
  end
end
