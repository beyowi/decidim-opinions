# frozen_string_literal: true

module Decidim
  module Opinions
    class Permissions < Decidim::DefaultPermissions
      def permissions
        return permission_action unless user

        # Delegate the admin permission checks to the admin permissions class
        return Decidim::Opinions::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin
        return permission_action if permission_action.scope != :public

        if permission_action.subject == :opinion
          apply_opinion_permissions(permission_action)
        elsif permission_action.subject == :collaborative_draft
          apply_collaborative_draft_permissions(permission_action)
        else
          permission_action
        end

        permission_action
      end

      private

      def apply_opinion_permissions(permission_action)
        case permission_action.action
        when :create
          can_create_opinion?
        when :edit
          can_edit_opinion?
        when :withdraw
          can_withdraw_opinion?
        when :amend
          can_create_amendment?
        when :vote
          can_vote_opinion?
        when :unvote
          can_unvote_opinion?
        when :report
          true
        end
      end

      def opinion
        @opinion ||= context.fetch(:opinion, nil) || context.fetch(:resource, nil)
      end

      def voting_enabled?
        return unless current_settings

        current_settings.votes_enabled? && !current_settings.votes_blocked?
      end

      def vote_limit_enabled?
        return unless component_settings

        component_settings.vote_limit.present? && component_settings.vote_limit.positive?
      end

      def remaining_votes
        return 1 unless vote_limit_enabled?

        opinions = Opinion.where(component: component)
        votes_count = OpinionVote.where(author: user, opinion: opinions).size
        component_settings.vote_limit - votes_count
      end

      def can_create_opinion?
        toggle_allow(authorized?(:create) && current_settings&.creation_enabled?)
      end

      def can_edit_opinion?
        toggle_allow(opinion && opinion.editable_by?(user))
      end

      def can_withdraw_opinion?
        toggle_allow(opinion && opinion.authored_by?(user))
      end

      def can_create_amendment?
        is_allowed = opinion &&
                     authorized?(:amend, resource: opinion) &&
                     current_settings&.amendments_enabled?

        toggle_allow(is_allowed)
      end

      def can_vote_opinion?
        is_allowed = opinion &&
                     authorized?(:vote, resource: opinion) &&
                     voting_enabled? &&
                     remaining_votes.positive?

        toggle_allow(is_allowed)
      end

      def can_unvote_opinion?
        is_allowed = opinion &&
                     authorized?(:vote, resource: opinion) &&
                     voting_enabled?

        toggle_allow(is_allowed)
      end

      def apply_collaborative_draft_permissions(permission_action)
        case permission_action.action
        when :create
          can_create_collaborative_draft?
        when :edit
          can_edit_collaborative_draft?
        when :publish
          can_publish_collaborative_draft?
        when :request_access
          can_request_access_collaborative_draft?
        when :react_to_request_access
          can_react_to_request_access_collaborative_draft?
        end
      end

      def collaborative_draft
        @collaborative_draft ||= context.fetch(:collaborative_draft, nil)
      end

      def collaborative_drafts_enabled?
        component_settings.collaborative_drafts_enabled
      end

      def can_create_collaborative_draft?
        return toggle_allow(false) unless collaborative_drafts_enabled?

        toggle_allow(current_settings&.creation_enabled? && authorized?(:create))
      end

      def can_edit_collaborative_draft?
        return toggle_allow(false) unless collaborative_drafts_enabled? && collaborative_draft.open?

        toggle_allow(collaborative_draft.editable_by?(user))
      end

      def can_publish_collaborative_draft?
        return toggle_allow(false) unless collaborative_drafts_enabled? && collaborative_draft.open?

        toggle_allow(collaborative_draft.created_by?(user))
      end

      def can_request_access_collaborative_draft?
        return toggle_allow(false) unless collaborative_drafts_enabled? && collaborative_draft.open?
        return toggle_allow(false) if collaborative_draft.requesters.include?(user)

        toggle_allow(!collaborative_draft.editable_by?(user))
      end

      def can_react_to_request_access_collaborative_draft?
        return toggle_allow(false) unless collaborative_drafts_enabled? && collaborative_draft.open?
        return toggle_allow(false) if collaborative_draft.requesters.include? user

        toggle_allow(collaborative_draft.created_by?(user))
      end
    end
  end
end
