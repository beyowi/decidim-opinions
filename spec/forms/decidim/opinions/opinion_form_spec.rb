# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe OpinionForm do
      let(:params) do
        super.merge(
          user_group_id: user_group_id
        )
      end

      it_behaves_like "a opinion form", user_group_check: true
    end
  end
end
