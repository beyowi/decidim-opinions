# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe PublishAnswers do
        subject { command.call }

        let(:command) { described_class.new(component, user, opinion_ids) }
        let(:opinion_ids) { opinions.map(&:id) }
        let(:opinions) { create_list(:opinion, 5, :accepted_not_published, component: component) }
        let(:component) { create(:opinion_component) }
        let(:user) { create(:user, :admin) }

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "publish the answers" do
          expect { subject }.to change { opinions.map { |opinion| opinion.reload.published_state? } .uniq } .to([true])
        end

        it "changes the opinions published state" do
          expect { subject }.to change { opinions.map { |opinion| opinion.reload.state } .uniq } .from([nil]).to(["accepted"])
        end

        it "traces the action", versioning: true do
          opinions.each do |opinion|
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with("publish_answer", opinion, user)
              .and_call_original
          end

          expect { subject }.to change(Decidim::ActionLog, :count)
          action_log = Decidim::ActionLog.last
          expect(action_log.version).to be_present
          expect(action_log.version.event).to eq "update"
        end

        it "notifies the answers" do
          opinions.each do |opinion|
            expect(NotifyOpinionAnswer)
              .to receive(:call)
              .with(opinion, nil)
          end

          subject
        end

        context "when opinion ids belong to other component" do
          let(:opinions) { create_list(:opinion, 5, :accepted) }

          it "broadcasts invalid" do
            expect { subject }.to broadcast(:invalid)
          end

          it "doesn't publish the answers" do
            expect { subject }.not_to(change { opinions.map { |opinion| opinion.reload.published_state? } .uniq })
          end

          it "doesn't trace the action" do
            expect(Decidim.traceability)
              .not_to receive(:perform_action!)

            subject
          end

          it "doesn't notify the answers" do
            expect(NotifyOpinionAnswer).not_to receive(:call)

            subject
          end
        end
      end
    end
  end
end
