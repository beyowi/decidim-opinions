# frozen_string_literal: true

require "spec_helper"

describe Decidim::Opinions::OpinionMentionedEvent do
  include_context "when a simple event"

  let(:event_name) { "decidim.events.opinions.opinion_mentioned" }
  let(:organization) { create :organization }
  let(:author) { create :user, organization: organization }

  let(:source_opinion) { create :opinion, component: create(:opinion_component, organization: organization), title: "Opinion A" }
  let(:mentioned_opinion) { create :opinion, component: create(:opinion_component, organization: organization), title: "Opinion B" }
  let(:resource) { source_opinion }
  let(:extra) do
    {
      mentioned_opinion_id: mentioned_opinion.id
    }
  end

  it_behaves_like "a simple event"

  describe "types" do
    subject { described_class }

    it "supports notifications" do
      expect(subject.types).to include :notification
    end

    it "supports emails" do
      expect(subject.types).to include :email
    end
  end

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("Your opinion \"#{mentioned_opinion.title}\" has been mentioned")
    end
  end

  context "with content" do
    let(:content) do
      "Your opinion \"#{mentioned_opinion.title}\" has been mentioned " \
        "<a href=\"#{resource_url}\">in this space</a> in the comments."
    end

    describe "email_intro" do
      let(:resource_url) { resource_locator(source_opinion).url }

      it "is generated correctly" do
        expect(subject.email_intro).to eq(content)
      end
    end

    describe "notification_title" do
      let(:resource_url) { resource_locator(source_opinion).path }

      it "is generated correctly" do
        expect(subject.notification_title).to include(content)
      end
    end
  end
end
