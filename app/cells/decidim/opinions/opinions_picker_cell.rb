# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Opinions
    # This cell renders a opinions picker.
    class OpinionsPickerCell < Decidim::ViewModel
      MAX_OPINIONS = 1000

      def show
        if filtered?
          render :opinions
        else
          render
        end
      end

      alias component model

      def filtered?
        !search_text.nil?
      end

      def picker_path
        request.path
      end

      def search_text
        params[:q]
      end

      def more_opinions?
        @more_opinions ||= more_opinions_count.positive?
      end

      def more_opinions_count
        @more_opinions_count ||= opinions_count - MAX_OPINIONS
      end

      def opinions_count
        @opinions_count ||= filtered_opinions.count
      end

      def decorated_opinions
        filtered_opinions.limit(MAX_OPINIONS).each do |opinion|
          yield Decidim::Opinions::OpinionPresenter.new(opinion)
        end
      end

      def filtered_opinions
        @filtered_opinions ||= if filtered?
                                  opinions.where("title ILIKE ?", "%#{search_text}%")
                                           .or(opinions.where("reference ILIKE ?", "%#{search_text}%"))
                                           .or(opinions.where("id::text ILIKE ?", "%#{search_text}%"))
                                else
                                  opinions
                                end
      end

      def opinions
        @opinions ||= Decidim.find_resource_manifest(:opinions).try(:resource_scope, component)
                       &.published
                       &.order(id: :asc)
      end

      def opinions_collection_name
        Decidim::Opinions::Opinion.model_name.human(count: 2)
      end
    end
  end
end
