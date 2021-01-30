# frozen-string_literal: true

module Decidim
  module Opinions
    class RejectedOpinionEvent < Decidim::Events::SimpleEvent
      include Decidim::Events::AuthorEvent

      def resource_text
        translated_attribute(resource.answer)
      end

      def event_has_roles?
        true
      end
    end
  end
end
