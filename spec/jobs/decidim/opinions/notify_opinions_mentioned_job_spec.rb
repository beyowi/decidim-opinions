# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe NotifyOpinionsMentionedJob do
      include_context "when creating a comment"
      subject { described_class }

      let(:comment) { create(:comment, commentable: commentable) }
      let(:opinion_component) { create(:opinion_component, organization: organization) }
      let(:opinion_metadata) { Decidim::ContentParsers::OpinionParser::Metadata.new([]) }
      let(:linked_opinion) { create(:opinion, component: opinion_component) }
      let(:linked_opinion_official) { create(:opinion, :official, component: opinion_component) }

      describe "integration" do
        it "is correctly scheduled" do
          ActiveJob::Base.queue_adapter = :test
          opinion_metadata[:linked_opinions] << linked_opinion
          opinion_metadata[:linked_opinions] << linked_opinion_official
          comment = create(:comment)

          expect do
            Decidim::Comments::CommentCreation.publish(comment, opinion: opinion_metadata)
          end.to have_enqueued_job.with(comment.id, opinion_metadata.linked_opinions)
        end
      end

      describe "with mentioned opinions" do
        let(:linked_opinions) do
          [
            linked_opinion.id,
            linked_opinion_official.id
          ]
        end

        let!(:space_admin) do
          create(:process_admin, participatory_process: linked_opinion_official.component.participatory_space)
        end

        it "notifies the author about it" do
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.opinions.opinion_mentioned",
              event_class: Decidim::Opinions::OpinionMentionedEvent,
              resource: commentable,
              affected_users: [linked_opinion.creator_author],
              extra: {
                comment_id: comment.id,
                mentioned_opinion_id: linked_opinion.id
              }
            )

          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.opinions.opinion_mentioned",
              event_class: Decidim::Opinions::OpinionMentionedEvent,
              resource: commentable,
              affected_users: [space_admin],
              extra: {
                comment_id: comment.id,
                mentioned_opinion_id: linked_opinion_official.id
              }
            )

          subject.perform_now(comment.id, linked_opinions)
        end
      end
    end
  end
end
