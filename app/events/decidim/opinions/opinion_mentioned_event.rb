# frozen-string_literal: true

module Decidim
  module Opinions
    class OpinionMentionedEvent < Decidim::Events::SimpleEvent
      include Decidim::ApplicationHelper

      i18n_attributes :mentioned_opinion_title

      private

      def mentioned_opinion_title
        present(mentioned_opinion).title
      end

      def mentioned_opinion
        @mentioned_opinion ||= Decidim::Opinions::Opinion.find(extra[:mentioned_opinion_id])
      end
    end
  end
end
