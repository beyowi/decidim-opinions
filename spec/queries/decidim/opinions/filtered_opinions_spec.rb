# frozen_string_literal: true

require "spec_helper"

describe Decidim::Opinions::FilteredOpinions do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, organization: organization) }
  let(:component) { create(:opinion_component, participatory_space: participatory_process) }
  let(:another_component) { create(:opinion_component, participatory_space: participatory_process) }

  let(:opinions) { create_list(:opinion, 3, component: component) }
  let(:old_opinions) { create_list(:opinion, 3, component: component, created_at: 10.days.ago) }
  let(:another_opinions) { create_list(:opinion, 3, component: another_component) }

  it "returns opinions included in a collection of components" do
    expect(described_class.for([component, another_component])).to match_array opinions.concat(old_opinions, another_opinions)
  end

  it "returns opinions created in a date range" do
    expect(described_class.for([component, another_component], 2.weeks.ago, 1.week.ago)).to match_array old_opinions
  end
end
