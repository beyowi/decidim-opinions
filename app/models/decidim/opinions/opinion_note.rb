# frozen_string_literal: true

module Decidim
  module Opinions
    # A opinion can include a notes created by admins.
    class OpinionNote < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      belongs_to :opinion, foreign_key: "decidim_opinion_id", class_name: "Decidim::Opinions::Opinion", counter_cache: true
      belongs_to :author, foreign_key: "decidim_author_id", class_name: "Decidim::User"

      default_scope { order(created_at: :asc) }

      def self.log_presenter_class_for(_log)
        Decidim::Opinions::AdminLog::OpinionNotePresenter
      end
    end
  end
end
