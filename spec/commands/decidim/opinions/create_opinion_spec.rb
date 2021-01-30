# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe CreateOpinion do
      let(:form_klass) { OpinionWizardCreateStepForm }
      let(:component) { create(:opinion_component) }
      let(:organization) { component.organization }
      let(:user) { create :user, :admin, :confirmed, organization: organization }
      let(:form) do
        form_klass.from_params(
          form_params
        ).with_context(
          current_user: user,
          current_organization: organization,
          current_participatory_space: component.participatory_space,
          current_component: component
        )
      end

      let(:author) { create(:user, organization: organization) }

      let(:user_group) do
        create(:user_group, :verified, organization: organization, users: [author])
      end

      describe "call" do
        let(:form_params) do
          {
            title: "A reasonable opinion title",
            body: "A reasonable opinion body",
            user_group_id: user_group.try(:id)
          }
        end

        let(:command) do
          described_class.new(form, author)
        end

        describe "when the form is not valid" do
          before do
            expect(form).to receive(:invalid?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "doesn't create a opinion" do
            expect do
              command.call
            end.not_to change(Decidim::Opinions::Opinion, :count)
          end
        end

        describe "when the form is valid" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "creates a new opinion" do
            expect do
              command.call
            end.to change(Decidim::Opinions::Opinion, :count).by(1)
          end

          it "traces the action", versioning: true do
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with(
                :create,
                Decidim::Opinions::Opinion,
                author,
                visibility: "public-only"
              ).and_call_original

            expect { described_class.call(form, author) }.to change(Decidim::ActionLog, :count).by(1)
          end

          context "with an author" do
            let(:user_group) { nil }

            it "sets the author" do
              command.call
              opinion = Decidim::Opinions::Opinion.last
              creator = opinion.creator

              expect(creator.author).to eq(author)
              expect(creator.user_group).to eq(nil)
            end

            it "adds the author as a follower" do
              command.call
              opinion = Decidim::Opinions::Opinion.last

              expect(opinion.followers).to include(author)
            end

            context "with a opinion limit" do
              let(:component) do
                create(:opinion_component, settings: { "opinion_limit" => 2 })
              end

              it "checks the author doesn't exceed the amount of opinions" do
                expect { command.call }.to broadcast(:ok)
                expect { command.call }.to broadcast(:ok)
                expect { command.call }.to broadcast(:invalid)
              end
            end
          end

          context "with a user group" do
            it "sets the user group" do
              command.call
              opinion = Decidim::Opinions::Opinion.last
              creator = opinion.creator

              expect(creator.author).to eq(author)
              expect(creator.user_group).to eq(user_group)
            end

            context "with a opinion limit" do
              let(:component) do
                create(:opinion_component, settings: { "opinion_limit" => 2 })
              end

              before do
                create_list(:opinion, 2, component: component, users: [author])
              end

              it "checks the user group doesn't exceed the amount of opinions independently of the author" do
                expect { command.call }.to broadcast(:ok)
                expect { command.call }.to broadcast(:ok)
                expect { command.call }.to broadcast(:invalid)
              end
            end
          end

          describe "the opinion limit excludes withdrawn opinions" do
            let(:component) do
              create(:opinion_component, settings: { "opinion_limit" => 1 })
            end

            describe "when the author is a user" do
              let(:user_group) { nil }

              before do
                create(:opinion, :withdrawn, users: [author], component: component)
              end

              it "checks the user doesn't exceed the amount of opinions" do
                expect { command.call }.to broadcast(:ok)
                expect { command.call }.to broadcast(:invalid)

                user_opinion_count = Decidim::Coauthorship.where(author: author, coauthorable_type: "Decidim::Opinions::Opinion").count
                expect(user_opinion_count).to eq(2)
              end
            end

            describe "when the author is a user_group" do
              before do
                create(:opinion, :withdrawn, users: [author], user_groups: [user_group], component: component)
              end

              it "checks the user_group doesn't exceed the amount of opinions" do
                expect { command.call }.to broadcast(:ok)
                expect { command.call }.to broadcast(:invalid)

                user_group_opinion_count = Decidim::Coauthorship.where(user_group: user_group, coauthorable_type: "Decidim::Opinions::Opinion").count
                expect(user_group_opinion_count).to eq(2)
              end
            end
          end
        end
      end
    end
  end
end
