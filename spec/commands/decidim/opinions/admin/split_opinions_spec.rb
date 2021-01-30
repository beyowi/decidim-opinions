# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe SplitOpinions do
        describe "call" do
          let!(:opinions) { Array(create(:opinion, component: current_component)) }
          let!(:current_component) { create(:opinion_component) }
          let!(:target_component) { create(:opinion_component, participatory_space: current_component.participatory_space) }
          let(:form) do
            instance_double(
              OpinionsSplitForm,
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

            it "creates two opinions for each original in the new component" do
              expect do
                command.call
              end.to change { Opinion.where(component: target_component).count }.by(2)
            end

            it "links the opinions" do
              command.call
              new_opinions = Opinion.where(component: target_component)

              linked = opinions.first.linked_resources(:opinions, "copied_from_component")

              expect(linked).to match_array(new_opinions)
            end

            it "only copies wanted attributes" do
              command.call
              opinion = opinions.first
              new_opinion = Opinion.where(component: target_component).last

              expect(new_opinion.title).to eq(opinion.title)
              expect(new_opinion.body).to eq(opinion.body)
              expect(new_opinion.creator_author).to eq(current_component.organization)
              expect(new_opinion.category).to eq(opinion.category)

              expect(new_opinion.state).to be_nil
              expect(new_opinion.answer).to be_nil
              expect(new_opinion.answered_at).to be_nil
              expect(new_opinion.reference).not_to eq(opinion.reference)
            end

            context "when spliting to the same component" do
              let(:same_component) { true }
              let!(:target_component) { current_component }
              let!(:opinions) { create_list(:opinion, 2, component: current_component) }

              it "only creates one copy for each opinion" do
                expect do
                  command.call
                end.to change { Opinion.where(component: current_component).count }.by(2)
              end

              context "when the original opinion has links to other opinions" do
                let(:previous_component) { create(:opinion_component, participatory_space: current_component.participatory_space) }
                let(:previous_opinions) { create(:opinion, component: previous_component) }

                before do
                  opinions.each do |opinion|
                    opinion.link_resources(previous_opinions, "copied_from_component")
                  end
                end

                it "links the copy to the same links the opinion has" do
                  new_opinions = Opinion.where(component: target_component).last(2)

                  new_opinions.each do |opinion|
                    linked = opinion.linked_resources(:opinions, "copied_from_component")
                    expect(linked).to eq([previous_opinions])
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
