# frozen_string_literal: true

module Decidim
  module Opinions
    # Simple helpers to handle markup variations for opinions
    module OpinionsHelper
      def opinion_reason_callout_args
        {
          announcement: {
            title: opinion_reason_callout_title,
            body: decidim_sanitize(translated_attribute(@opinion.answer))
          },
          callout_class: opinion_reason_callout_class
        }
      end

      def opinion_reason_callout_class
        case @opinion.state
        when "accepted"
          "success"
        when "evaluating"
          "warning"
        when "rejected"
          "alert"
        else
          ""
        end
      end

      def opinion_reason_callout_title
        i18n_key = case @opinion.state
                   when "evaluating"
                     "opinion_in_evaluation_reason"
                   else
                     "opinion_#{@opinion.state}_reason"
                   end

        t(i18n_key, scope: "decidim.opinions.opinions.show")
      end

      def filter_opinions_state_values
        Decidim::CheckBoxesTreeHelper::TreeNode.new(
          Decidim::CheckBoxesTreeHelper::TreePoint.new("", t("decidim.opinions.application_helper.filter_state_values.all")),
          [
            Decidim::CheckBoxesTreeHelper::TreePoint.new("accepted", t("decidim.opinions.application_helper.filter_state_values.accepted")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("evaluating", t("decidim.opinions.application_helper.filter_state_values.evaluating")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("not_answered", t("decidim.opinions.application_helper.filter_state_values.not_answered")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("rejected", t("decidim.opinions.application_helper.filter_state_values.rejected"))
          ]
        )
      end

      def opinion_has_costs?
        @opinion.cost.present? &&
          translated_attribute(@opinion.cost_report).present? &&
          translated_attribute(@opinion.execution_period).present?
      end

      def resource_version(resource, options = {})
        return unless resource.respond_to?(:amendable?) && resource.amendable?

        super
      end
    end
  end
end
