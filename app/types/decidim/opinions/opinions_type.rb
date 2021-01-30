# frozen_string_literal: true

module Decidim
  module Opinions
    OpinionsType = GraphQL::ObjectType.define do
      interfaces [-> { Decidim::Core::ComponentInterface }]

      name "Opinions"
      description "A opinions component of a participatory space."

      connection :opinions,
                 type: OpinionType.connection_type,
                 description: "List all opinions",
                 function: OpinionListHelper.new(model_class: Opinion)

      field :opinion,
            type: OpinionType,
            description: "Finds one opinion",
            function: OpinionFinderHelper.new(model_class: Opinion)
    end

    class OpinionListHelper < Decidim::Core::ComponentListBase
      argument :order, OpinionInputSort, "Provides several methods to order the results"
      argument :filter, OpinionInputFilter, "Provides several methods to filter the results"

      # only querying published posts
      def query_scope
        super.published
      end
    end

    class OpinionFinderHelper < Decidim::Core::ComponentFinderBase
      argument :id, !types.ID, "The ID of the opinion"

      # only querying published posts
      def query_scope
        super.published
      end
    end
  end
end
