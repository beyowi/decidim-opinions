# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe MergeOpinions do
        describe "call" do
          let!(:opinions) { create_list(:opinion, 3, component: current_component) }
          let!(:current_component) { create(:opinion_component) }
          let!(:target_component) { create(:opinion_component, participatory_space: current_component.participatory_space) }
          let(:form) do
            instance_double(
              OpinionsMergeForm,
              current_component: current_component,
              current_organization: current_component.organization,
              target_component: target_component,
              opinions: opinions,
              valid?: valid,
              same_component?: same_component,
              current_user: create(:user, :admin, organization: current_component.organization)
            )
          end
          let(:command) { described_class.new(form) }
          let(:same_component) { false }

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

            it "creates a opinion in the new component" do
              expect do
                command.call
              end.to change { Opinion.where(component: target_component).count }.by(1)
            end

            it "links the opinions" do
              command.call
              opinion = Opinion.where(component: target_component).last

              linked = opinion.linked_resources(:opinions, "copied_from_component")

              expect(linked).to match_array(opinions)
            end

            it "only merges wanted attributes" do
              command.call
              new_opinion = Opinion.where(component: target_component).last
              opinion = opinions.first

              expect(new_opinion.title).to eq(opinion.title)
              expect(new_opinion.body).to eq(opinion.body)
              expect(new_opinion.creator_author).to eq(current_component.organization)
              expect(new_opinion.category).to eq(opinion.category)

              expect(new_opinion.state).to be_nil
              expect(new_opinion.answer).to be_nil
              expect(new_opinion.answered_at).to be_nil
              expect(new_opinion.reference).not_to eq(opinion.reference)
            end

            context "when merging from the same component" do
              let(:same_component) { true }
              let(:target_component) { current_component }

              it "deletes the original opinions" do
                command.call
                opinion_ids = opinions.map(&:id)

                expect(Decidim::Opinions::Opinion.where(id: opinion_ids)).to be_empty
              end

              it "links the merged opinion to the links the other opinions had" do
                other_component = create(:opinion_component, participatory_space: current_component.participatory_space)
                other_opinions = create_list(:opinion, 3, component: other_component)

                opinions.each_with_index do |opinion, index|
                  opinion.link_resources(other_opinions[index], "copied_from_component")
                end

                command.call

                opinion = Opinion.where(component: target_component).last
                linked = opinion.linked_resources(:opinions, "copied_from_component")
                expect(linked).to match_array(other_opinions)
              end
            end
          end
        end
      end
    end
  end
end
