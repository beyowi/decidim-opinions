# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Opinions
    # This cell renders the opinion card for an instance of a Opinion
    # the default size is the Medium Card (:m)
    class OpinionCell < Decidim::ViewModel
      include OpinionCellsHelper
      include Cell::ViewModel::Partial
      include Messaging::ConversationHelper

      def show
        cell card_size, model, options
      end

      private

      def card_size
        "decidim/opinions/opinion_m"
      end

      def resource_path
        resource_locator(model).path
      end

      def current_participatory_space
        model.component.participatory_space
      end

      def current_component
        model.component
      end

      def component_name
        translated_attribute model.component.name
      end

      def component_type_name
        model.class.model_name.human
      end

      def participatory_space_name
        translated_attribute current_participatory_space.title
      end

      def participatory_space_type_name
        translated_attribute current_participatory_space.model_name.human
      end
    end
  end
end
