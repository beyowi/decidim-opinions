# frozen_string_literal: true

module Decidim
  module Opinions
    module Metrics
      class AcceptedOpinionsMetricManage < Decidim::Opinions::Metrics::OpinionsMetricManage
        def metric_name
          "accepted_opinions"
        end

        private

        def query
          return @query if @query

          spaces = Decidim.participatory_space_manifests.flat_map do |manifest|
            manifest.participatory_spaces.call(@organization).public_spaces
          end
          @query = Decidim::Opinions::Opinion.where(component: visible_component_ids_from_spaces(spaces)).joins(:component)
                                               .left_outer_joins(:category)
          @query = @query.where("decidim_opinions_opinions.created_at <= ?", end_time).accepted
          @query = @query.group("decidim_categorizations.id", :participatory_space_type, :participatory_space_id)
          @query
        end

        def quantity
          @quantity ||= query.where("decidim_opinions_opinions.created_at >= ?", start_time).count
        end
      end
    end
  end
end
