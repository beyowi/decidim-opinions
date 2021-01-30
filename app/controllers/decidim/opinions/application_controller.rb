# frozen_string_literal: true

module Decidim
  module Opinions
    # This controller is the abstract class from which all other controllers of
    # this engine inherit.
    #
    # Note that it inherits from `Decidim::Components::BaseController`, which
    # override its layout and provide all kinds of useful methods.
    class ApplicationController < Decidim::Components::BaseController
      helper Decidim::Messaging::ConversationHelper
      helper_method :opinion_limit_reached?

      def opinion_limit
        return nil if component_settings.opinion_limit.zero?

        component_settings.opinion_limit
      end

      def opinion_limit_reached?
        return false unless opinion_limit

        opinions.where(author: current_user).count >= opinion_limit
      end

      def opinions
        Opinion.where(component: current_component)
      end
    end
  end
end
