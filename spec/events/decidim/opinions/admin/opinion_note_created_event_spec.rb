# frozen_string_literal: true

require "spec_helper"

describe Decidim::Opinions::Admin::OpinionNoteCreatedEvent do
  let(:resource) { create :opinion, title: ::Faker::Lorem.characters(25) }
  let(:event_name) { "decidim.events.opinions.admin.opinion_note_created" }
  let(:component) { resource.component }
  let(:admin_opinion_info_path) { "/admin/participatory_processes/#{participatory_space.slug}/components/#{component.id}/manage/opinions/#{resource.id}" }
  let(:admin_opinion_info_url) { "http://#{organization.host}/admin/participatory_processes/#{participatory_space.slug}/components/#{component.id}/manage/opinions/#{resource.id}" }

  include_context "when a simple event"
  it_behaves_like "a simple event"

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("Someone left a note on opinion #{resource.title}.")
    end
  end

  describe "email_intro" do
    it "is generated correctly" do
      expect(subject.email_intro)
        .to eq(%(Someone has left a note on the opinion "#{resource.title}". Check it out at <a href="#{admin_opinion_info_url}">the admin panel</a>))
    end
  end

  describe "email_outro" do
    it "is generated correctly" do
      expect(subject.email_outro)
        .to eq("You have received this notification because you can valuate the opinion.")
    end
  end

  describe "notification_title" do
    it "is generated correctly" do
      expect(subject.notification_title)
        .to include(%(Someone has left a note on the opinion <a href="#{resource_path}">#{resource.title}</a>. Check it out at <a href="#{admin_opinion_info_path}">the admin panel</a>))
    end
  end
end
