# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe ImportOpinions do
        describe "call" do
          let!(:opinion) { create(:opinion, :accepted) }
          let(:keep_authors) { false }
          let(:current_component) do
            create(
              :opinion_component,
              participatory_space: opinion.component.participatory_space
            )
          end
          let(:form) do
            instance_double(
              OpinionsImportForm,
              origin_component: opinion.component,
              current_component: current_component,
              current_organization: current_component.organization,
              keep_authors: keep_authors,
              states: states,
              current_user: create(:user),
              valid?: valid
            )
          end
          let(:states) { ["accepted"] }
          let(:command) { described_class.new(form) }

          describe "when the form is not valid" do
            let(:valid) { false }

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create the opinion" do
              expect do
                command.call
              end.to change(Opinion, :count).by(0)
            end
          end

          describe "when the form is valid" do
            let(:valid) { true }

            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "creates the opinions" do
              expect do
                command.call
              end.to change { Opinion.where(component: current_component).count }.by(1)
            end

            context "when a opinion was already imported" do
              let(:second_opinion) { create(:opinion, :accepted, component: opinion.component) }

              before do
                command.call
                second_opinion
              end

              it "doesn't import it again" do
                expect do
                  command.call
                end.to change { Opinion.where(component: current_component).count }.by(1)

                titles = Opinion.where(component: current_component).map(&:title)
                expect(titles).to match_array([opinion.title, second_opinion.title])
              end
            end

            it "links the opinions" do
              command.call

              linked = opinion.linked_resources(:opinions, "copied_from_component")
              new_opinion = Opinion.where(component: current_component).last

              expect(linked).to include(new_opinion)
            end

            it "only imports wanted attributes" do
              command.call

              new_opinion = Opinion.where(component: current_component).last
              expect(new_opinion.title).to eq(opinion.title)
              expect(new_opinion.body).to eq(opinion.body)
              expect(new_opinion.creator_author).to eq(current_component.organization)
              expect(new_opinion.category).to eq(opinion.category)

              expect(new_opinion.state).to be_nil
              expect(new_opinion.answer).to be_nil
              expect(new_opinion.answered_at).to be_nil
              expect(new_opinion.reference).not_to eq(opinion.reference)
            end

            describe "when keep_authors is true" do
              let(:keep_authors) { true }

              it "only keeps the opinion authors" do
                command.call

                new_opinion = Opinion.where(component: current_component).last
                expect(new_opinion.title).to eq(opinion.title)
                expect(new_opinion.body).to eq(opinion.body)
                expect(new_opinion.creator_author).to eq(opinion.creator_author)
              end
            end

            describe "opinion states" do
              let(:states) { %w(not_answered rejected) }

              before do
                create(:opinion, :rejected, component: opinion.component)
                create(:opinion, component: opinion.component)
              end

              it "only imports opinions from the selected states" do
                expect do
                  command.call
                end.to change { Opinion.where(component: current_component).count }.by(2)

                expect(Opinion.where(component: current_component).pluck(:title)).not_to include(opinion.title)
              end
            end

            describe "when the opinion has attachments" do
              let!(:attachment) do
                create(:attachment, attached_to: opinion)
              end

              it "duplicates the attachments" do
                expect do
                  command.call
                end.to change(Attachment, :count).by(1)

                new_opinion = Opinion.where(component: current_component).last
                expect(new_opinion.attachments.count).to eq(1)
              end
            end
          end
        end
      end
    end
  end
end
