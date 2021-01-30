# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe ApplicationHelper do
      let(:helper) do
        Class.new.tap do |v|
          v.extend(Decidim::Opinions::ApplicationHelper)
        end
      end

      describe "humanize_opinion_state" do
        subject { helper.humanize_opinion_state(state) }

        context "when it is accepted" do
          let(:state) { "accepted" }

          it { is_expected.to eq("Accepted") }
        end

        context "when it is rejected" do
          let(:state) { "rejected" }

          it { is_expected.to eq("Rejected") }
        end

        context "when it is nil" do
          let(:state) { nil }

          it { is_expected.to eq("Not answered") }
        end

        context "when it is withdrawn" do
          let(:state) { "withdrawn" }

          it { is_expected.to eq("Withdrawn") }
        end
      end
    end
  end
end
