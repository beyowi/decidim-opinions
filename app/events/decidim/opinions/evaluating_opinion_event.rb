# frozen-string_literal: true

module Decidim
  module Opinions
    class EvaluatingOpinionEvent < Decidim::Events::SimpleEvent
      def event_has_roles?
        true
      end
    end
  end
end
