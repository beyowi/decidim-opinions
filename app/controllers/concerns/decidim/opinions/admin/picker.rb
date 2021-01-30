# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Opinions
    module Admin
      module Picker
        extend ActiveSupport::Concern

        included do
          helper Decidim::Opinions::Admin::OpinionsPickerHelper
        end

        def opinions_picker
          render :opinions_picker, layout: false
        end
      end
    end
  end
end
