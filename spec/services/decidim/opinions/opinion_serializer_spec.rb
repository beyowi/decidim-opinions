# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe OpinionSerializer do
      subject do
        described_class.new(opinion)
      end

      let!(:opinion) { create(:opinion, :accepted) }
      let!(:category) { create(:category, participatory_space: component.participatory_space) }
      let!(:scope) { create(:scope, organization: component.participatory_space.organization) }
      let(:participatory_process) { component.participatory_space }
      let(:component) { opinion.component }

      let!(:meetings_component) { create(:component, manifest_name: "meetings", participatory_space: participatory_process) }
      let(:meetings) { create_list(:meeting, 2, component: meetings_component) }

      let!(:opinions_component) { create(:component, manifest_name: "opinions", participatory_space: participatory_process) }
      let(:other_opinions) { create_list(:opinion, 2, component: opinions_component) }

      let(:expected_answer) do
        answer = opinion.answer
        Decidim.available_locales.each_with_object({}) do |locale, result|
          result[locale.to_s] = if answer.is_a?(Hash)
                                  answer[locale.to_s] || ""
                                else
                                  ""
                                end
        end
      end

      before do
        opinion.update!(category: category)
        opinion.update!(scope: scope)
        opinion.link_resources(meetings, "opinions_from_meeting")
        opinion.link_resources(other_opinions, "copied_from_component")
      end

      describe "#serialize" do
        let(:serialized) { subject.serialize }

        it "serializes the id" do
          expect(serialized).to include(id: opinion.id)
        end

        it "serializes the category" do
          expect(serialized[:category]).to include(id: category.id)
          expect(serialized[:category]).to include(name: category.name)
        end

        it "serializes the scope" do
          expect(serialized[:scope]).to include(id: scope.id)
          expect(serialized[:scope]).to include(name: scope.name)
        end

        it "serializes the title" do
          expect(serialized).to include(title: opinion.title)
        end

        it "serializes the body" do
          expect(serialized).to include(body: opinion.body)
        end

        it "serializes the amount of supports" do
          expect(serialized).to include(supports: opinion.opinion_votes_count)
        end

        it "serializes the amount of comments" do
          expect(serialized).to include(comments: opinion.comments.count)
        end

        it "serializes the date of creation" do
          expect(serialized).to include(published_at: opinion.published_at)
        end

        it "serializes the url" do
          expect(serialized[:url]).to include("http", opinion.id.to_s)
        end

        it "serializes the component" do
          expect(serialized[:component]).to include(id: opinion.component.id)
        end

        it "serializes the meetings" do
          expect(serialized[:meeting_urls].length).to eq(2)
          expect(serialized[:meeting_urls].first).to match(%r{http.*/meetings})
        end

        it "serializes the participatory space" do
          expect(serialized[:participatory_space]).to include(id: participatory_process.id)
          expect(serialized[:participatory_space][:url]).to include("http", participatory_process.slug)
        end

        it "serializes the state" do
          expect(serialized).to include(state: opinion.state)
        end

        it "serializes the reference" do
          expect(serialized).to include(reference: opinion.reference)
        end

        it "serializes the answer" do
          expect(serialized).to include(answer: expected_answer)
        end

        it "serializes the amount of attachments" do
          expect(serialized).to include(attachments: opinion.attachments.count)
        end

        it "serializes the endorsements" do
          expect(serialized[:endorsements]).to include(total_count: opinion.endorsements.count)
          expect(serialized[:endorsements]).to include(user_endorsements: opinion.endorsements.for_listing.map { |identity| identity.normalized_author&.name })
        end

        it "serializes related opinions" do
          expect(serialized[:related_opinions].length).to eq(2)
          expect(serialized[:related_opinions].first).to match(%r{http.*/opinions})
        end

        it "serializes if opinion is_amend" do
          expect(serialized).to include(is_amend: opinion.emendation?)
        end

        it "serializes the original opinion" do
          expect(serialized[:original_opinion]).to include(title: opinion&.amendable&.title)
          expect(serialized[:original_opinion][:url]).to be_nil || include("http", opinion.id.to_s)
        end

        context "with opinion having an answer" do
          let!(:opinion) { create(:opinion, :with_answer) }

          it "serializes the answer" do
            expect(serialized).to include(answer: expected_answer)
          end
        end
      end
    end
  end
end
