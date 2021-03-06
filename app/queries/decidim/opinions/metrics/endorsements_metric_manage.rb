# frozen_string_literal: true

module Decidim
  module Opinions
    module Metrics
      class EndorsementsMetricManage < Decidim::MetricManage
        def metric_name
          "endorsements"
        end

        def save
          cumulative.each do |key, cumulative_value|
            next if cumulative_value.zero?

            quantity_value = quantity[key] || 0
            category_id, space_type, space_id, opinion_id = key
            record = Decidim::Metric.find_or_initialize_by(day: @day.to_s, metric_type: @metric_name,
                                                           organization: @organization, decidim_category_id: category_id,
                                                           participatory_space_type: space_type, participatory_space_id: space_id,
                                                           related_object_type: "Decidim::Opinions::Opinion", related_object_id: opinion_id)
            record.assign_attributes(cumulative: cumulative_value, quantity: quantity_value)
            record.save!
          end
        end

        private

        def query
          return @query if @query

          components = Decidim::Component.where(participatory_space: retrieve_participatory_spaces).published
          opinions = Decidim::Opinions::Opinion.where(component: components).except_withdrawn
          join_components = "INNER JOIN decidim_components ON decidim_components.manifest_name = 'opinions' AND opinions.decidim_component_id = decidim_components.id"
          join_categories = <<~EOJOINCATS
            LEFT OUTER JOIN decidim_categorizations
            ON (opinions.id = decidim_categorizations.categorizable_id
            AND decidim_categorizations.categorizable_type = 'Decidim::Opinions::Opinion')
          EOJOINCATS
          @query = Decidim::Endorsement.joins("INNER JOIN decidim_opinions_opinions opinions ON resource_id = opinions.id")
                                       .joins(join_components)
                                       .joins(join_categories)
                                       .where(resource_id: opinions.pluck(:id))
                                       .where(resource_type: Decidim::Opinions::Opinion.name)
          @query = @query.where("decidim_endorsements.created_at <= ?", end_time)
          @query = @query.group("decidim_categorizations.id",
                                :participatory_space_type,
                                :participatory_space_id,
                                :resource_id)
          @query
        end

        def quantity
          @quantity ||= query.where("decidim_endorsements.created_at >= ?", start_time).count
        end
      end
    end
  end
end
