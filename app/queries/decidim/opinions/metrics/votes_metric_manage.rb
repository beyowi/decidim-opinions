# frozen_string_literal: true

module Decidim
  module Opinions
    module Metrics
      class VotesMetricManage < Decidim::MetricManage
        def metric_name
          "votes"
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

          spaces = Decidim.participatory_space_manifests.flat_map do |manifest|
            manifest.participatory_spaces.call(@organization).public_spaces
          end
          opinion_ids = Decidim::Opinions::Opinion.where(component: visible_component_ids_from_spaces(spaces.pluck(:id))).except_withdrawn.not_hidden.pluck(:id)
          @query = Decidim::Opinions::OpinionVote.joins(opinion: :component)
                                                   .left_outer_joins(opinion: :category)
                                                   .where(opinion: opinion_ids)
          @query = @query.where("decidim_opinions_opinion_votes.created_at <= ?", end_time)
          @query = @query.group("decidim_categorizations.id",
                                :participatory_space_type,
                                :participatory_space_id,
                                :decidim_opinion_id)
          @query
        end

        def quantity
          @quantity ||= query.where("decidim_opinions_opinion_votes.created_at >= ?", start_time).count
        end
      end
    end
  end
end
