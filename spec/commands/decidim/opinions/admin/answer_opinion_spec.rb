# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe AnswerOpinion do
        subject { command.call }

        let(:command) { described_class.new(form, opinion) }
        let(:opinion) { create(:opinion) }
        let(:current_user) { create(:user, :admin) }
        let(:form) do
          OpinionAnswerForm.from_params(form_params).with_context(
            current_user: current_user,
            current_component: opinion.component,
            current_organization: opinion.component.organization
          )
        end

        let(:form_params) do
          {
            internal_state: "rejected",
            answer: { en: "Foo" },
            cost: 2000,
            cost_report: { en: "Cost report" },
            execution_period: { en: "Execution period" }
          }
        end

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "publish the opinion answer" do
          expect { subject }.to change { opinion.reload.published_state? } .to(true)
        end

        it "changes the opinion state" do
          expect { subject }.to change { opinion.reload.state } .to("rejected")
        end

        it "traces the action", versioning: true do
          expect(Decidim.traceability)
            .to receive(:perform_action!)
            .with("answer", opinion, form.current_user)
            .and_call_original

          expect { subject }.to change(Decidim::ActionLog, :count)
          action_log = Decidim::ActionLog.last
          expect(action_log.version).to be_present
          expect(action_log.version.event).to eq "update"
        end

        it "notifies the opinion answer" do
          expect(NotifyOpinionAnswer)
            .to receive(:call)
            .with(opinion, nil)

          subject
        end

        context "when the form is not valid" do
          before do
            expect(form).to receive(:invalid?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { subject }.to broadcast(:invalid)
          end

          it "doesn't change the opinion state" do
            expect { subject }.not_to(change { opinion.reload.state })
          end
        end

        context "when applying over an already answered opinion" do
          let(:opinion) { create(:opinion, :accepted) }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "changes the opinion state" do
            expect { subject }.to change { opinion.reload.state } .to("rejected")
          end

          it "notifies the opinion new answer" do
            expect(NotifyOpinionAnswer)
              .to receive(:call)
              .with(opinion, "accepted")

            subject
          end
        end

        context "when opinion answer should not be published immediately" do
          let(:opinion) { create(:opinion, component: component) }
          let(:component) { create(:opinion_component, :without_publish_answers_immediately) }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "changes the opinion internal state" do
            expect { subject }.to change { opinion.reload.internal_state } .to("rejected")
          end

          it "doesn't publish the opinion answer" do
            expect { subject }.not_to change { opinion.reload.published_state? } .from(false)
          end

          it "doesn't notify the opinion answer" do
            expect(NotifyOpinionAnswer)
              .not_to receive(:call)

            subject
          end
        end
      end
    end
  end
end
