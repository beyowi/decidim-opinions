# frozen_string_literal: true

require "spec_helper"

describe "Opinions in process home", type: :system do
  include_context "with a component"
  let(:manifest_name) { "opinions" }
  let(:opinions_count) { 2 }
  let(:highlighted_opinions) { opinions_count * 2 }

  before do
    allow(Decidim::Opinions.config)
      .to receive(:participatory_space_highlighted_opinions_limit)
      .and_return(highlighted_opinions)
  end

  context "when there are no opinions" do
    it "does not show the highlighted opinions section" do
      visit resource_locator(participatory_process).path
      expect(page).not_to have_css(".highlighted_opinions")
    end
  end

  context "when there are opinions" do
    let!(:opinions) { create_list(:opinion, opinions_count, component: component) }
    let!(:drafted_opinions) { create_list(:opinion, opinions_count, :draft, component: component) }
    let!(:hidden_opinions) { create_list(:opinion, opinions_count, :hidden, component: component) }
    let!(:withdrawn_opinions) { create_list(:opinion, opinions_count, :withdrawn, component: component) }

    it "shows the highlighted opinions section" do
      visit resource_locator(participatory_process).path

      within ".highlighted_opinions" do
        expect(page).to have_css(".card--opinion", count: opinions_count)

        opinions_titles = opinions.map(&:title)
        drafted_opinions_titles = drafted_opinions.map(&:title)
        hidden_opinions_titles = hidden_opinions.map(&:title)
        withdrawn_opinions_titles = withdrawn_opinions.map(&:title)

        highlighted_opinions = page.all(".card--opinion .card__title").map(&:text)
        expect(opinions_titles).to include(*highlighted_opinions)
        expect(drafted_opinions_titles).not_to include(*highlighted_opinions)
        expect(hidden_opinions_titles).not_to include(*highlighted_opinions)
        expect(withdrawn_opinions_titles).not_to include(*highlighted_opinions)
      end
    end

    context "and there are more opinions than those that can be shown" do
      let!(:opinions) { create_list(:opinion, highlighted_opinions + 2, component: component) }

      it "shows the amount of opinions configured" do
        visit resource_locator(participatory_process).path

        within ".highlighted_opinions" do
          expect(page).to have_css(".card--opinion", count: highlighted_opinions)

          opinions_titles = opinions.map(&:title)
          highlighted_opinions = page.all(".card--opinion .card__title").map(&:text)
          expect(opinions_titles).to include(*highlighted_opinions)
        end
      end
    end
  end
end
