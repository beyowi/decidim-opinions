# frozen_string_literal: true

module Decidim
  module Opinions
    # A collaborative_draft can accept requests to coauthor and contribute
    class CollaborativeDraftCollaboratorRequest < Opinions::ApplicationRecord
      validates :collaborative_draft, :user, presence: true

      belongs_to :collaborative_draft, class_name: "Decidim::Opinions::CollaborativeDraft", foreign_key: :decidim_opinions_collaborative_draft_id
      belongs_to :user, class_name: "Decidim::User", foreign_key: :decidim_user_id
    end
  end
end
