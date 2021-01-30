# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe OpinionActivityCell, type: :cell do
      controller Decidim::LastActivitiesController

      let!(:opinion) { create(:opinion) }
      let(:hashtag) { create(:hashtag, name: "myhashtag") }
      let(:action_log) do
        create(
          :action_log,
          resource: opinion,
          organization: opinion.organization,
          component: opinion.component,
          participatory_space: opinion.participatory_space
        )
      end

      context "when rendering" do
        it "renders the card" do
          html = cell("decidim/opinions/opinion_activity", action_log).call
          expect(html).to have_css(".card__content")
          expect(html).to have_content("New opinion")
        end

        context "when the opinion has a hashtags" do
          before do
            body = "Opinion with #myhashtag"
            parsed_body = Decidim::ContentProcessor.parse(body, current_organization: opinion.organization)
            opinion.body = parsed_body.rewrite
            opinion.save
          end

          it "correctly renders opinions with mentions" do
            html = cell("decidim/opinions/opinion_activity", action_log).call
            expect(html).to have_no_content("gid://")
            expect(html).to have_content("#myhashtag")
          end
        end
      end
    end
  end
end
