# frozen-string_literal: true

module Decidim
  module Opinions
    module Admin
      class UpdateOpinionCategoryEvent < Decidim::Events::SimpleEvent
        include Decidim::Events::AuthorEvent
      end
    end
  end
end
