# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe OpinionAnswerForm do
        subject { form }

        let(:organization) { opinions_component.participatory_space.organization }
        let(:state) { "accepted" }
        let(:answer) { Decidim::Faker::Localized.sentence(3) }
        let(:opinions_component) { create :opinion_component }
        let(:cost) { nil }
        let(:cost_report) { nil }
        let(:execution_period) { nil }
        let(:params) do
          {
            internal_state: state,
            answer: answer,
            cost: cost,
            cost_report: cost_report,
            execution_period: execution_period
          }
        end

        let(:form) do
          described_class.from_params(params).with_context(
            current_component: opinions_component,
            current_organization: organization
          )
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        context "when the state is not valid" do
          let(:state) { "foo" }

          it { is_expected.to be_invalid }
        end

        context "when there's no state" do
          let(:state) { nil }

          it { is_expected.to be_invalid }
        end

        context "when rejecting a opinion" do
          let(:state) { "rejected" }

          context "and there's no answer" do
            let(:answer) { nil }

            it { is_expected.to be_invalid }
          end
        end

        context "when accepting the opinion" do
          let(:state) { "accepted" }

          context "and costs are enabled" do
            before do
              opinions_component.update!(
                step_settings: {
                  opinions_component.participatory_space.active_step.id => {
                    answers_with_costs: true
                  }
                }
              )
            end

            it { is_expected.to be_invalid }

            context "and cost data is filled" do
              let(:cost) { 20_000 }
              let(:cost_report) { { en: "Cost report" } }
              let(:execution_period) { { en: "Execution period" } }

              it { is_expected.to be_valid }
            end
          end
        end
      end
    end
  end
end
