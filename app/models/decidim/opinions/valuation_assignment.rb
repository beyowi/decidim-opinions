# frozen_string_literal: true

module Decidim
  module Opinions
    # A valuation assignment links a opinion and a Valuator user role.
    # Valuators will be users in charge of defining the monetary cost of a
    # opinion.
    class ValuationAssignment < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      belongs_to :opinion, foreign_key: "decidim_opinion_id", class_name: "Decidim::Opinions::Opinion"
      belongs_to :valuator_role, polymorphic: true

      def self.log_presenter_class_for(_log)
        Decidim::Opinions::AdminLog::ValuationAssignmentPresenter
      end

      def valuator
        valuator_role.user
      end
    end
  end
end
