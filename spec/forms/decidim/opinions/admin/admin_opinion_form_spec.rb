# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe OpinionForm do
        it_behaves_like "a opinion form", skip_etiquette_validation: true
        it_behaves_like "a opinion form with meeting as author", skip_etiquette_validation: true
      end
    end
  end
end
