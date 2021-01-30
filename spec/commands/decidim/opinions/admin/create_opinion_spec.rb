# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe CreateOpinion do
        let(:form_klass) { OpinionForm }
        let(:component) { create(:opinion_component) }
        let(:organization) { component.organization }
        let(:meeting_component) { create(:meeting_component, participatory_space: component.participatory_space) }
        let(:meetings) { create_list(:meeting, 3, component: meeting_component) }
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
        let(:has_address) { false }
        let(:address) { nil }
        let(:latitude) { 40.1234 }
        let(:longitude) { 2.1234 }
        let(:attachment_params) { nil }
        let(:uploaded_photos) { [] }
        let(:photos) { [] }
        let(:created_in_meeting) { false }
        let(:meeting_id) { nil }

        describe "call" do
          let(:form_params) do
            {
              title: "A reasonable opinion title",
              body: "A reasonable opinion body",
              address: address,
              has_address: has_address,
              attachment: attachment_params,
              photos: photos,
              add_photos: uploaded_photos,
              created_in_meeting: created_in_meeting,
              meeting_id: meeting_id,
              user_group_id: nil
            }
          end

          let(:command) do
            described_class.new(form)
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

            context "when opinion comes from a meeting" do
              let(:created_in_meeting) { true }
              let(:meeting_id) { meetings.first.id }
              let(:meeting_as_author) { meetings.first }

              it "sets the meeting as author" do
                command.call

                expect(Decidim::Opinions::Opinion.last.authors).to include(meeting_as_author)
              end

              it "links the opinion and the meeting" do
                command.call
                opinion = Decidim::Opinions::Opinion.last
                opinion_linked_meetings = opinion.linked_resources(:meeting, "opinions_from_meeting")

                expect(opinion_linked_meetings).to include(meeting_as_author)
              end

              context "when the meeting is already linked to other opinions" do
                let(:another_opinion) { create :opinion, component: component }

                it "keeps the old opinions linked" do
                  another_opinion.link_resources(meeting_as_author, "opinions_from_meeting")
                  command.call
                  opinion = Decidim::Opinions::Opinion.last
                  linked_opinions = meeting_as_author.linked_resources(:opinion, "opinions_from_meeting")

                  expect(linked_opinions).to match_array([opinion, another_opinion])
                end
              end
            end

            context "when opinion is official" do
              it "sets the organization as author" do
                command.call

                expect(Decidim::Opinions::Opinion.last.authors).to include(organization)
              end
            end

            it "traces the action", versioning: true do
              expect(Decidim.traceability)
                .to receive(:perform_action!)
                .with(:create, Decidim::Opinions::Opinion, kind_of(Decidim::User), visibility: "all")
                .and_call_original

              expect { command.call }.to change(Decidim::ActionLog, :count)
              action_log = Decidim::ActionLog.last
              expect(action_log.version).to be_present
            end

            it "notifies the space followers" do
              follower = create(:user, organization: component.participatory_space.organization)
              create(:follow, followable: component.participatory_space, user: follower)

              expect(Decidim::EventsManager)
                .to receive(:publish)
                .with(
                  event: "decidim.events.opinions.opinion_published",
                  event_class: Decidim::Opinions::PublishOpinionEvent,
                  resource: kind_of(Decidim::Opinions::Opinion),
                  followers: [follower],
                  extra: {
                    participatory_space: true
                  }
                )

              command.call
            end

            context "when geocoding is enabled" do
              let(:component) { create(:opinion_component, :with_geocoding_enabled) }

              context "when the has address checkbox is checked" do
                let(:has_address) { true }

                context "when the address is present" do
                  let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }

                  before do
                    stub_geocoding(address, [latitude, longitude])
                  end

                  it "sets the latitude and longitude" do
                    command.call
                    opinion = Decidim::Opinions::Opinion.last

                    expect(opinion.latitude).to eq(latitude)
                    expect(opinion.longitude).to eq(longitude)
                  end
                end
              end
            end

            context "when attachments are allowed", processing_uploads_for: Decidim::AttachmentUploader do
              let(:component) { create(:opinion_component, :with_attachments_allowed) }
              let(:attachment_params) do
                {
                  title: "My attachment",
                  file: Decidim::Dev.test_file("city.jpeg", "image/jpeg")
                }
              end

              it "creates an atachment for the opinion" do
                expect { command.call }.to change(Decidim::Attachment, :count).by(1)
                last_opinion = Decidim::Opinions::Opinion.last
                last_attachment = Decidim::Attachment.last
                expect(last_attachment.attached_to).to eq(last_opinion)
              end

              context "when attachment is left blank" do
                let(:attachment_params) do
                  {
                    title: ""
                  }
                end

                it "broadcasts ok" do
                  expect { command.call }.to broadcast(:ok)
                end
              end
            end

            context "when galleries are allowed" do
              it_behaves_like "admin creates resource gallery" do
                let(:component) { create(:opinion_component, :with_attachments_allowed) }
                let(:command) { described_class.new(form) }
                let(:resource_class) { Decidim::Opinions::Opinion }
                let(:attachment_params) { { title: "" } }
              end
            end
          end
        end
      end
    end
  end
end