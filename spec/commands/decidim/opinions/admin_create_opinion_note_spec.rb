# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe CreateOpinionNote do
        describe "call" do
          let(:opinion) { create(:opinion) }
          let(:organization) { opinion.component.organization }
          let(:current_user) { create(:user, :admin, organization: organization) }
          let!(:another_admin) { create(:user, :admin, organization: organization) }
          let(:valuation_assignment) { create(:valuation_assignment, opinion: opinion) }
          let!(:valuator) { valuation_assignment.valuator }
          let(:form) { OpinionNoteForm.from_params(form_params).with_context(current_user: current_user, current_organization: organization) }

          let(:form_params) do
            {
              body: "A reasonable private note"
            }
          end

          let(:command) { described_class.new(form, opinion) }

          describe "when the form is not valid" do
            before do
              expect(form).to receive(:invalid?).and_return(true)
            end

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create the opinion note" do
              expect do
                command.call
              end.to change(OpinionVote, :count).by(0)
            end
          end

          describe "when the form is valid" do
            before do
              expect(form).to receive(:invalid?).and_return(false)
            end

            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "creates the opinion notes" do
              expect do
                command.call
              end.to change(OpinionNote, :count).by(1)
            end

            it "traces the action", versioning: true do
              expect(Decidim.traceability)
                .to receive(:create!)
                .with(OpinionNote, current_user, hash_including(:body, :opinion, :author), resource: hash_including(:title))
                .and_call_original

              expect { command.call }.to change(ActionLog, :count)
              action_log = Decidim::ActionLog.last
              expect(action_log.version).to be_present
            end

            it "notifies the admins and the valuators" do
              expect(Decidim::EventsManager)
                .to receive(:publish)
                .once
                .ordered
                .with(
                  event: "decidim.events.opinions.admin.opinion_note_created",
                  event_class: Decidim::Opinions::Admin::OpinionNoteCreatedEvent,
                  resource: opinion,
                  affected_users: a_collection_containing_exactly(another_admin, valuator)
                )

              command.call
            end
          end
        end
      end
    end
  end
end
