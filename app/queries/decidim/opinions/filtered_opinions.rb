# frozen_string_literal: true

module Decidim
  module Opinions
    # A class used to find opinions filtered by components and a date range
    class FilteredOpinions < Rectify::Query
      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # components - An array of Decidim::Component
      # start_at - A date to filter resources created after it
      # end_at - A date to filter resources created before it.
      def self.for(components, start_at = nil, end_at = nil)
        new(components, start_at, end_at).query
      end

      # Initializes the class.
      #
      # components - An array of Decidim::Component
      # start_at - A date to filter resources created after it
      # end_at - A date to filter resources created before it.
      def initialize(components, start_at = nil, end_at = nil)
        @components = components
        @start_at = start_at
        @end_at = end_at
      end

      # Finds the Opinions scoped to an array of components and filtered
      # by a range of dates.
      def query
        opinions = Decidim::Opinions::Opinion.where(component: @components)
        opinions = opinions.where("created_at >= ?", @start_at) if @start_at.present?
        opinions = opinions.where("created_at <= ?", @end_at) if @end_at.present?
        opinions
      end
    end
  end
end
