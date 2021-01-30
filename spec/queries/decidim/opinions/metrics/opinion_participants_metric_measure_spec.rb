# frozen_string_literal: true

require "spec_helper"

describe Decidim::Opinions::Metrics::OpinionParticipantsMetricMeasure do
  let(:day) { Time.zone.yesterday }
  let(:organization) { create(:organization) }
  let(:not_valid_resource) { create(:dummy_resource) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }

  let(:opinions_component) { create(:opinion_component, :published, participatory_space: participatory_space) }
  let!(:opinion) { create(:opinion, :with_endorsements, published_at: day, component: opinions_component) }
  let!(:old_opinion) { create(:opinion, :with_endorsements, published_at: day - 1.week, component: opinions_component) }
  let!(:opinion_votes) { create_list(:opinion_vote, 10, created_at: day, opinion: opinion) }
  let!(:old_opinion_votes) { create_list(:opinion_vote, 5, created_at: day - 1.week, opinion: old_opinion) }
  let!(:opinion_endorsements) do
    5.times.collect do
      create(:endorsement, created_at: day, resource: opinion, author: build(:user, organization: organization))
    end
  end
  # TOTAL Participants for Opinions:
  #  Cumulative: 22 ( 2 opinion, 15 votes, 5 endorsements )
  #  Quantity: 16 ( 1 opinion, 10 votes, 5 endorsements )

  context "when executing class" do
    it "fails to create object with an invalid resource" do
      manager = described_class.new(day, not_valid_resource)

      expect(manager).not_to be_valid
    end

    it "calculates" do
      result = described_class.new(day, opinions_component).calculate

      expect(result[:cumulative_users].count).to eq(22)
      expect(result[:quantity_users].count).to eq(16)
    end

    it "does not found any result for past days" do
      result = described_class.new(day - 1.month, opinions_component).calculate

      expect(result[:cumulative_users].count).to eq(0)
      expect(result[:quantity_users].count).to eq(0)
    end
  end
end
