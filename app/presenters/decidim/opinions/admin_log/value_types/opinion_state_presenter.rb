# frozen_string_literal: true

module Decidim
  module Opinions
    module AdminLog
      module ValueTypes
        class OpinionStatePresenter < Decidim::Log::ValueTypes::DefaultPresenter
          def present
            return unless value

            h.t(value, scope: "decidim.opinions.admin.opinion_answers.edit", default: value)
          end
        end
      end
    end
  end
end
