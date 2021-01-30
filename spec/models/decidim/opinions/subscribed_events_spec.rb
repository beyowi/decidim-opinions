# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe Opinion do
      subject { opinion }

      let!(:organization) { create(:organization) }
      let!(:component) { create(:component, organization: organization, manifest_name: "opinions") }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:author) { create(:user, :admin, organization: organization) }
      let!(:opinion) { create(:opinion, component: component, users: [author]) }
      let(:resource) do
        build(:dummy_resource)
      end

      context "when event is created" do
        before do
          link_name = "included_opinions"
          event_name = "decidim.resourceable.#{link_name}.created"
          payload = {
            from_type: "Decidim::Accountability::Result", from_id: resource.id,
            to_type: opinion.class.name, to_id: opinion.id
          }
          ActiveSupport::Notifications.instrument event_name, this: payload do
            Decidim::ResourceLink.create!(
              from: resource,
              to: resource,
              name: link_name,
              data: {}
            )
          end
        end

        it "is accepted" do
          opinion.reload
          expect(opinion.state).to eq("accepted")
        end
      end
    end
  end
end
