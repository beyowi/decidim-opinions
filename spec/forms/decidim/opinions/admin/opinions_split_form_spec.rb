# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe OpinionsSplitForm do
        subject { form }

        let(:opinions) { create_list(:opinion, 2, component: component) }
        let(:component) { create(:opinion_component) }
        let(:target_component) { create(:opinion_component, participatory_space: component.participatory_space) }
        let(:params) do
          {
            target_component_id: [target_component.try(:id).to_s],
            opinion_ids: opinions.map(&:id)
          }
        end

        let(:form) do
          described_class.from_params(params).with_context(
            current_component: component,
            current_participatory_space: component.participatory_space
          )
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        context "without a target component" do
          let(:target_component) { nil }

          it { is_expected.to be_invalid }
        end

        context "when not enough opinions" do
          let(:opinions) { [] }

          it { is_expected.to be_invalid }
        end

        context "when given a target component from another space" do
          let(:target_component) { create(:opinion_component) }

          it { is_expected.to be_invalid }
        end

        context "when merging to the same component" do
          let(:target_component) { component }
          let(:opinions) { create_list(:opinion, 3, :official, component: component) }

          context "when the opinion is not official" do
            let(:opinions) { create_list(:opinion, 3, component: component) }

            it { is_expected.to be_invalid }
          end

          context "when a opinion has a vote" do
            before do
              create(:opinion_vote, opinion: opinions.sample)
            end

            it { is_expected.to be_invalid }
          end

          context "when a opinion has an endorsement" do
            before do
              create(:endorsement, resource: opinions.sample, author: build(:user, organization: component.participatory_space.organization))
            end

            it { is_expected.to be_invalid }
          end
        end
      end
    end
  end
end
