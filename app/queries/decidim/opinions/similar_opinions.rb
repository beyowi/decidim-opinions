# frozen_string_literal: true

module Decidim
  module Opinions
    # Class used to retrieve similar opinions.
    class SimilarOpinions < Rectify::Query
      include Decidim::TranslationsHelper

      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # components - Decidim::CurrentComponent
      # opinion - Decidim::Opinions::Opinion
      def self.for(components, opinion)
        new(components, opinion).query
      end

      # Initializes the class.
      #
      # components - Decidim::CurrentComponent
      # opinion - Decidim::Opinions::Opinion
      def initialize(components, opinion)
        @components = components
        @opinion = opinion
      end

      # Retrieves similar opinions
      def query
        Decidim::Opinions::Opinion
          .where(component: @components)
          .published
          .where(
            "GREATEST(#{title_similarity}, #{body_similarity}) >= ?",
            @opinion.title,
            @opinion.body,
            Decidim::Opinions.similarity_threshold
          )
          .limit(Decidim::Opinions.similarity_limit)
      end

      private

      def title_similarity
        "similarity(title, ?)"
      end

      def body_similarity
        "similarity(body, ?)"
      end
    end
  end
end
