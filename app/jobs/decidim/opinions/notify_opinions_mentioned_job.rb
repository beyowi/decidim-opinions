# frozen_string_literal: true

module Decidim
  module Opinions
    class NotifyOpinionsMentionedJob < ApplicationJob
      def perform(comment_id, linked_opinions)
        comment = Decidim::Comments::Comment.find(comment_id)

        linked_opinions.each do |opinion_id|
          opinion = Opinion.find(opinion_id)
          affected_users = opinion.notifiable_identities

          Decidim::EventsManager.publish(
            event: "decidim.events.opinions.opinion_mentioned",
            event_class: Decidim::Opinions::OpinionMentionedEvent,
            resource: comment.root_commentable,
            affected_users: affected_users,
            extra: {
              comment_id: comment.id,
              mentioned_opinion_id: opinion_id
            }
          )
        end
      end
    end
  end
end
