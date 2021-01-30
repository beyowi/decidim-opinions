# frozen_string_literal: true

module Decidim
  module Opinions
    # Custom helpers, scoped to the opinions engine.
    #
    module ApplicationHelper
      include Decidim::Comments::CommentsHelper
      include PaginateHelper
      include OpinionVotesHelper
      include ::Decidim::EndorsableHelper
      include ::Decidim::FollowableHelper
      include Decidim::MapHelper
      include Decidim::Opinions::MapHelper
      include CollaborativeDraftHelper
      include ControlVersionHelper
      include Decidim::RichTextEditorHelper
      include Decidim::CheckBoxesTreeHelper

      delegate :minimum_votes_per_user, to: :component_settings

      # Public: The state of a opinion in a way a human can understand.
      #
      # state - The String state of the opinion.
      #
      # Returns a String.
      def humanize_opinion_state(state)
        I18n.t(state, scope: "decidim.opinions.answers", default: :not_answered)
      end

      # Public: The css class applied based on the opinion state.
      #
      # state - The String state of the opinion.
      #
      # Returns a String.
      def opinion_state_css_class(state)
        case state
        when "accepted"
          "text-success"
        when "rejected"
          "text-alert"
        when "evaluating"
          "text-warning"
        when "withdrawn"
          "text-alert"
        else
          "text-info"
        end
      end

      # Public: The state of a opinion in a way a human can understand.
      #
      # state - The String state of the opinion.
      #
      # Returns a String.
      def humanize_collaborative_draft_state(state)
        I18n.t("decidim.opinions.collaborative_drafts.states.#{state}", default: :open)
      end

      # Public: The css class applied based on the collaborative draft state.
      #
      # state - The String state of the collaborative draft.
      #
      # Returns a String.
      def collaborative_draft_state_badge_css_class(state)
        case state
        when "open"
          "success"
        when "withdrawn"
          "alert"
        when "published"
          "secondary"
        end
      end

      def opinion_limit_enabled?
        opinion_limit.present?
      end

      def minimum_votes_per_user_enabled?
        minimum_votes_per_user.positive?
      end

      def not_from_collaborative_draft(opinion)
        opinion.linked_resources(:opinions, "created_from_collaborative_draft").empty?
      end

      def not_from_participatory_text(opinion)
        opinion.participatory_text_level.nil?
      end

      # If the opinion is official or the rich text editor is enabled on the
      # frontend, the opinion body is considered as safe content; that's unless
      # the opinion comes from a collaborative_draft or a participatory_text.
      def safe_content?
        rich_text_editor_in_public_views? && not_from_collaborative_draft(@opinion) ||
          (@opinion.official? || @opinion.official_meeting?) && not_from_participatory_text(@opinion)
      end

      # If the content is safe, HTML tags are sanitized, otherwise, they are stripped.
      def render_opinion_body(opinion)
        body = present(opinion).body(links: true, strip_tags: !safe_content?)
        body = simple_format(body, {}, sanitize: false)

        return body unless safe_content?

        decidim_sanitize(body)
      end

      # Returns :text_area or :editor based on the organization' settings.
      def text_editor_for_opinion_body(form)
        options = {
          class: "js-hashtags",
          hashtaggable: true,
          value: form_presenter.body(extras: false).strip
        }

        text_editor_for(form, :body, options)
      end

      def opinion_limit
        return if component_settings.opinion_limit.zero?

        component_settings.opinion_limit
      end

      def votes_given
        @votes_given ||= OpinionVote.where(
          opinion: Opinion.where(component: current_component),
          author: current_user
        ).count
      end

      def votes_count_for(model, from_opinions_list)
        render partial: "decidim/opinions/opinions/participatory_texts/opinion_votes_count.html", locals: { opinion: model, from_opinions_list: from_opinions_list }
      end

      def vote_button_for(model, from_opinions_list)
        render partial: "decidim/opinions/opinions/participatory_texts/opinion_vote_button.html", locals: { opinion: model, from_opinions_list: from_opinions_list }
      end

      def endorsers_for(opinion)
        opinion.endorsements.for_listing.map { |identity| present(identity.normalized_author) }
      end

      def form_has_address?
        @form.address.present? || @form.has_address
      end

      def authors_for(collaborative_draft)
        collaborative_draft.identities.map { |identity| present(identity) }
      end

      def show_voting_rules?
        return false unless votes_enabled?

        return true if vote_limit_enabled?
        return true if threshold_per_opinion_enabled?
        return true if opinion_limit_enabled?
        return true if can_accumulate_supports_beyond_threshold?
        return true if minimum_votes_per_user_enabled?
      end

      def filter_type_values
        [
          ["all", t("decidim.opinions.application_helper.filter_type_values.all")],
          ["opinions", t("decidim.opinions.application_helper.filter_type_values.opinions")],
          ["amendments", t("decidim.opinions.application_helper.filter_type_values.amendments")]
        ]
      end

      # Options to filter Opinions by activity.
      def activity_filter_values
        base = [
          ["all", t(".all")],
          ["my_opinions", t(".my_opinions")]
        ]
        base += [["voted", t(".voted")]] if current_settings.votes_enabled?
        base
      end
    end
  end
end
