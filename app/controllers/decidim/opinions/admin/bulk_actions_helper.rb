# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      module BulkActionsHelper
        def opinion_find(id)
          Decidim::Opinions::Opinion.find(id)
        end
      end
    end
  end
end