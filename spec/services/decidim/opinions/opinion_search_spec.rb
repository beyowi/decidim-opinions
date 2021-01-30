# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe OpinionSearch do
      let(:component) { create(:component, manifest_name: "opinions") }
      let(:scope1) { create :scope, organization: component.organization }
      let(:scope2) { create :scope, organization: component.organization }
      let(:subscope1) { create :scope, organization: component.organization, parent: scope1 }
      let(:participatory_process) { component.participatory_space }
      let(:user) { create(:user, organization: component.organization) }
      let!(:opinion) { create(:opinion, component: component, scope: scope1) }

      describe "results" do
        subject do
          described_class.new(
            component: component,
            activity: activity,
            search_text: search_text,
            state: states,
            origin: origins,
            related_to: related_to,
            scope_id: scope_ids,
            category_id: category_ids,
            current_user: user
          ).results
        end

        let(:activity) { [] }
        let(:search_text) { nil }
        let(:origins) { nil }
        let(:related_to) { nil }
        let(:states) { nil }
        let(:scope_ids) { nil }
        let(:category_ids) { nil }

        it "only includes opinions from the given component" do
          other_opinion = create(:opinion)

          expect(subject).to include(opinion)
          expect(subject).not_to include(other_opinion)
        end

        describe "search_text filter" do
          let(:search_text) { "dog" }

          it "returns the opinions containing the search in the title or the body" do
            create_list(:opinion, 3, component: component)
            create(:opinion, title: "A dog", component: component)
            create(:opinion, body: "There is a dog in the office", component: component)

            expect(subject.size).to eq(2)
          end
        end

        describe "activity filter" do
          context "when filtering by supported" do
            let(:activity) { "voted" }

            it "returns the opinions voted by the user" do
              create_list(:opinion, 3, component: component)
              create(:opinion_vote, opinion: Opinion.first, author: user)

              expect(subject.size).to eq(1)
            end
          end

          context "when filtering by my opinions" do
            let(:activity) { "my_opinions" }

            it "returns the opinions created by the user" do
              create_list(:opinion, 3, component: component)
              create(:opinion, component: component, users: [user])

              expect(subject.size).to eq(1)
            end
          end
        end

        describe "origin filter" do
          context "when filtering official opinions" do
            let(:origins) { %w(official) }

            it "returns only official opinions" do
              official_opinions = create_list(:opinion, 3, :official, component: component)
              create_list(:opinion, 3, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(official_opinions)
            end
          end

          context "when filtering citizen opinions" do
            let(:origins) { %w(citizens) }
            let(:another_user) { create(:user, organization: component.organization) }

            it "returns only citizen opinions" do
              create_list(:opinion, 3, :official, component: component)
              citizen_opinions = create_list(:opinion, 2, component: component)
              opinion.add_coauthor(another_user)
              citizen_opinions << opinion

              expect(subject.size).to eq(3)
              expect(subject).to match_array(citizen_opinions)
            end
          end

          context "when filtering user groups opinions" do
            let(:origins) { %w(user_group) }
            let(:user_group) { create :user_group, :verified, users: [user], organization: user.organization }

            it "returns only user groups opinions" do
              create(:opinion, :official, component: component)
              user_group_opinion = create(:opinion, component: component)
              user_group_opinion.coauthorships.clear
              user_group_opinion.add_coauthor(user, user_group: user_group)

              expect(subject.size).to eq(1)
              expect(subject).to eq([user_group_opinion])
            end
          end

          context "when filtering meetings opinions" do
            let(:origins) { %w(meeting) }
            let(:meeting) { create :meeting }

            it "returns only meeting opinions" do
              create(:opinion, :official, component: component)
              meeting_opinion = create(:opinion, :official_meeting, component: component)

              expect(subject.size).to eq(1)
              expect(subject).to eq([meeting_opinion])
            end
          end
        end

        describe "state filter" do
          context "when filtering for default states" do
            it "returns all except withdrawn opinions" do
              create_list(:opinion, 3, :withdrawn, component: component)
              other_opinions = create_list(:opinion, 3, component: component)
              other_opinions << opinion

              expect(subject.size).to eq(4)
              expect(subject).to match_array(other_opinions)
            end
          end

          context "when filtering :except_rejected opinions" do
            let(:states) { %w(accepted evaluating not_answered) }

            it "hides withdrawn and rejected opinions" do
              create(:opinion, :withdrawn, component: component)
              create(:opinion, :rejected, component: component)
              accepted_opinion = create(:opinion, :accepted, component: component)

              expect(subject.size).to eq(2)
              expect(subject).to match_array([accepted_opinion, opinion])
            end
          end

          context "when filtering accepted opinions" do
            let(:states) { %w(accepted) }

            it "returns only accepted opinions" do
              accepted_opinions = create_list(:opinion, 3, :accepted, component: component)
              create_list(:opinion, 3, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(accepted_opinions)
            end
          end

          context "when filtering rejected opinions" do
            let(:states) { %w(rejected) }

            it "returns only rejected opinions" do
              create_list(:opinion, 3, component: component)
              rejected_opinions = create_list(:opinion, 3, :rejected, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(rejected_opinions)
            end
          end

          context "when filtering withdrawn opinions" do
            let(:states) { %w(withdrawn) }

            it "returns only withdrawn opinions" do
              create_list(:opinion, 3, component: component)
              withdrawn_opinions = create_list(:opinion, 3, :withdrawn, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(withdrawn_opinions)
            end
          end
        end

        describe "scope_id filter" do
          let!(:opinion2) { create(:opinion, component: component, scope: scope2) }
          let!(:opinion3) { create(:opinion, component: component, scope: subscope1) }

          context "when a parent scope id is being sent" do
            let(:scope_ids) { [scope1.id] }

            it "filters opinions by scope" do
              expect(subject).to match_array [opinion, opinion3]
            end
          end

          context "when a subscope id is being sent" do
            let(:scope_ids) { [subscope1.id] }

            it "filters opinions by scope" do
              expect(subject).to eq [opinion3]
            end
          end

          context "when multiple ids are sent" do
            let(:scope_ids) { [scope2.id, scope1.id] }

            it "filters opinions by scope" do
              expect(subject).to match_array [opinion, opinion2, opinion3]
            end
          end

          context "when `global` is being sent" do
            let!(:resource_without_scope) { create(:opinion, component: component, scope: nil) }
            let(:scope_ids) { ["global"] }

            it "returns opinions without a scope" do
              expect(subject).to eq [resource_without_scope]
            end
          end

          context "when `global` and some ids is being sent" do
            let!(:resource_without_scope) { create(:opinion, component: component, scope: nil) }
            let(:scope_ids) { ["global", scope2.id, scope1.id] }

            it "returns opinions without a scope and with selected scopes" do
              expect(subject).to match_array [resource_without_scope, opinion, opinion2, opinion3]
            end
          end
        end

        describe "category_id filter" do
          let(:category1) { create :category, participatory_space: participatory_process }
          let(:category2) { create :category, participatory_space: participatory_process }
          let(:child_category) { create :category, participatory_space: participatory_process, parent: category2 }
          let!(:opinion2) { create(:opinion, component: component, category: category1) }
          let!(:opinion3) { create(:opinion, component: component, category: category2) }
          let!(:opinion4) { create(:opinion, component: component, category: child_category) }

          context "when no category filter is present" do
            it "includes all opinions" do
              expect(subject).to match_array [opinion, opinion2, opinion3, opinion4]
            end
          end

          context "when a category is selected" do
            let(:category_ids) { [category2.id] }

            it "includes only opinions for that category and its children" do
              expect(subject).to match_array [opinion3, opinion4]
            end
          end

          context "when a subcategory is selected" do
            let(:category_ids) { [child_category.id] }

            it "includes only opinions for that category" do
              expect(subject).to eq [opinion4]
            end
          end

          context "when `without` is being sent" do
            let(:category_ids) { ["without"] }

            it "returns opinions without a category" do
              expect(subject).to eq [opinion]
            end
          end

          context "when `without` and some category id is being sent" do
            let(:category_ids) { ["without", category1.id] }

            it "returns opinions without a category and with the selected category" do
              expect(subject).to match_array [opinion, opinion2]
            end
          end
        end

        describe "related_to filter" do
          context "when filtering by related to meetings" do
            let(:related_to) { "Decidim::Meetings::Meeting".underscore }
            let(:meetings_component) { create(:component, manifest_name: "meetings", participatory_space: participatory_process) }
            let(:meeting) { create :meeting, component: meetings_component }

            it "returns only opinions related to meetings" do
              related_opinion = create(:opinion, :accepted, component: component)
              related_opinion2 = create(:opinion, :accepted, component: component)
              create_list(:opinion, 3, component: component)
              meeting.link_resources([related_opinion], "opinions_from_meeting")
              related_opinion2.link_resources([meeting], "opinions_from_meeting")

              expect(subject).to match_array([related_opinion, related_opinion2])
            end
          end

          context "when filtering by related to resources" do
            let(:related_to) { "Decidim::DummyResources::DummyResource".underscore }
            let(:dummy_component) { create(:component, manifest_name: "dummy", participatory_space: participatory_process) }
            let(:dummy_resource) { create :dummy_resource, component: dummy_component }

            it "returns only opinions related to results" do
              related_opinion = create(:opinion, :accepted, component: component)
              related_opinion2 = create(:opinion, :accepted, component: component)
              create_list(:opinion, 3, component: component)
              dummy_resource.link_resources([related_opinion], "included_opinions")
              related_opinion2.link_resources([dummy_resource], "included_opinions")

              expect(subject).to match_array([related_opinion, related_opinion2])
            end
          end
        end
      end
    end
  end
end
