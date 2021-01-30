# frozen_string_literal: true

module Decidim
  module Opinions
    module AdminLog
      # This class holds the logic to present a `Decidim::Opinions::OpinionNote`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    OpinionNotePresenter.new(action_log, view_helpers).present
      class OpinionNotePresenter < Decidim::Log::BasePresenter
        private

        def diff_fields_mapping
          {
            body: :string
          }
        end

        def action_string
          case action
          when "create"
            "decidim.opinions.admin_log.opinion_note.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.opinion_note"
        end
      end
    end
  end
end
