# frozen_string_literal: true

module Decidim
  module Opinions
    module AdminLog
      # This class holds the logic to present a `Decidim::Opinions::Opinion`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    OpinionPresenter.new(action_log, view_helpers).present
      class OpinionPresenter < Decidim::Log::BasePresenter
        private

        def resource_presenter
          @resource_presenter ||= Decidim::Opinions::Log::ResourcePresenter.new(action_log.resource, h, action_log.extra["resource"])
        end

        def diff_fields_mapping
          {
            title: "Decidim::Opinions::AdminLog::ValueTypes::OpinionTitleBodyPresenter",
            body: "Decidim::Opinions::AdminLog::ValueTypes::OpinionTitleBodyPresenter",
            state: "Decidim::Opinions::AdminLog::ValueTypes::OpinionStatePresenter",
            answered_at: :date,
            answer: :i18n
          }
        end

        def action_string
          case action
          when "answer", "create", "update", "publish_answer"
            "decidim.opinions.admin_log.opinion.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.opinion"
        end

        def has_diff?
          action == "answer" || super
        end
      end
    end
  end
end
