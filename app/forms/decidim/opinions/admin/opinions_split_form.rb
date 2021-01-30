# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A form object to be used when admin users wants to split two or more
      # opinions into a new one to another opinion component in the same space.
      class OpinionsSplitForm < OpinionsForkForm
      end
    end
  end
end
