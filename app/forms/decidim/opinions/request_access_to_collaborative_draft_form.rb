# frozen_string_literal: true

module Decidim
  module Opinions
    # A form object to be used when public users want to request acces to a Collaborative Draft.
    class RequestAccessToCollaborativeDraftForm < Decidim::Form
      mimic :collaborative_draft

      attribute :id, String
      attribute :state, String

      validates :id, presence: true
      validates :state, presence: true, inclusion: { in: %w(open) }

      def collaborative_draft
        @collaborative_draft ||= Decidim::Opinions::CollaborativeDraft.find id
      end
    end
  end
end
