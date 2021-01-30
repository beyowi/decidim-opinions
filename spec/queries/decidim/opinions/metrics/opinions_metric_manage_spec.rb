# frozen_string_literal: true

require "spec_helper"

describe Decidim::Opinions::Metrics::OpinionsMetricManage do
  let(:organization) { create(:organization) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:component) { create(:opinion_component, :published, participatory_space: participatory_space) }
  let(:day) { Time.zone.yesterday }
  let!(:opinions) { create_list(:opinion, 3, published_at: day, component: component) }

  include_context "when managing metrics"

  context "when executing" do
    it "creates new metric records" do
      registry = generate_metric_registry

      expect(registry.collect(&:day)).to eq([day])
      expect(registry.collect(&:cumulative)).to eq([3])
      expect(registry.collect(&:quantity)).to eq([3])
    end

    it "does not create any record if there is no data" do
      registry = generate_metric_registry("2017-01-01")

      expect(Decidim::Metric.count).to eq(0)
      expect(registry).to be_empty
    end

    it "updates metric records" do
      create(:metric, metric_type: "opinions", day: day, cumulative: 1, quantity: 1, organization: organization, category: nil, participatory_space: participatory_space)
      registry = generate_metric_registry

      expect(Decidim::Metric.count).to eq(1)
      expect(registry.collect(&:cumulative)).to eq([3])
      expect(registry.collect(&:quantity)).to eq([3])
    end

    context "when calculating the metrics" do
      let(:moderation) { create(:moderation, reportable: opinions[0], report_count: 1, participatory_space: participatory_space) }
      let!(:report) { create(:report, moderation: moderation) }

      it "filters the data correctly" do
        opinions[0].moderation.update!(hidden_at: Time.current)
        opinions[1].update!(published_at: nil)
        opinions[2].update!(state: "withdrawn")

        registry = generate_metric_registry

        expect(registry.collect(&:cumulative)).to eq([])
        expect(registry.collect(&:quantity)).to eq([])
      end
    end
  end
end
