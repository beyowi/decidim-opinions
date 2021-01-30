# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe DestroyOpinion do
      describe "call" do
        let(:component) { create(:opinion_component) }
        let(:organization) { component.organization }
        let(:current_user) { create(:user, organization: organization) }
        let(:other_user) { create(:user, organization: organization) }
        let!(:opinion) { create :opinion, component: component, users: [current_user] }
        let(:opinion_draft) { create(:opinion, :draft, component: component, users: [current_user]) }
        let!(:opinion_draft_other) { create :opinion, component: component, users: [other_user] }

        it "broadcasts ok" do
          expect { described_class.call(opinion_draft, current_user) }.to broadcast(:ok)
          expect { opinion_draft.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "broadcasts invalid when the opinion is not a draft" do
          expect { described_class.call(opinion, current_user) }.to broadcast(:invalid)
        end

        it "broadcasts invalid when the opinion_draft is from another author" do
          expect { described_class.call(opinion_draft_other, current_user) }.to broadcast(:invalid)
        end
      end
    end
  end
end
