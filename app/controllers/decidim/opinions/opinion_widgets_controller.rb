# frozen_string_literal: true

module Decidim
  module Opinions
    class OpinionWidgetsController < Decidim::WidgetsController
      helper Opinions::ApplicationHelper

      private

      def model
        @model ||= Opinion.where(component: params[:component_id]).find(params[:opinion_id])
      end

      def iframe_url
        @iframe_url ||= opinion_opinion_widget_url(model)
      end
    end
  end
end
