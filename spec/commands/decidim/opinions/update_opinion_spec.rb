# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    describe UpdateOpinion do
      let(:form_klass) { OpinionForm }

      let(:component) { create(:opinion_component, :with_extra_hashtags, suggested_hashtags: suggested_hashtags.join(" ")) }
      let(:organization) { component.organization }
      let(:form) do
        form_klass.from_params(
          form_params
        ).with_context(
          current_organization: organization,
          current_participatory_space: component.participatory_space,
          current_component: component
        )
      end

      let!(:opinion) { create :opinion, component: component, users: [author] }
      let(:author) { create(:user, organization: organization) }

      let(:user_group) do
        create(:user_group, :verified, organization: organization, users: [author])
      end

      let(:has_address) { false }
      let(:address) { nil }
      let(:latitude) { 40.1234 }
      let(:longitude) { 2.1234 }
      let(:suggested_hashtags) { [] }

      describe "call" do
        let(:form_params) do
          {
            title: "A reasonable opinion title",
            body: "A reasonable opinion body",
            address: address,
            has_address: has_address,
            user_group_id: user_group.try(:id),
            suggested_hashtags: suggested_hashtags
          }
        end

        let(:command) do
          described_class.new(form, author, opinion)
        end

        describe "when the form is not valid" do
          before do
            expect(form).to receive(:invalid?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "doesn't update the opinion" do
            expect do
              command.call
            end.not_to change(opinion, :title)
          end
        end

        describe "when the opinion is not editable by the user" do
          before do
            expect(opinion).to receive(:editable_by?).and_return(false)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "doesn't update the opinion" do
            expect do
              command.call
            end.not_to change(opinion, :title)
          end
        end

        context "when the author changinng the author to one that has reached the opinion limit" do
          let!(:other_opinion) { create :opinion, component: component, users: [author], user_groups: [user_group] }
          let(:component) { create(:opinion_component, :with_opinion_limit) }

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end
        end

        describe "when the form is valid" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "updates the opinion" do
            expect do
              command.call
            end.to change(opinion, :title)
          end

          context "with an author" do
            let(:user_group) { nil }

            it "sets the author" do
              command.call
              opinion = Decidim::Opinions::Opinion.last

              expect(opinion).to be_authored_by(author)
              expect(opinion.identities.include?(user_group)).to be false
            end
          end

          context "with a user group" do
            it "sets the user group" do
              command.call
              opinion = Decidim::Opinions::Opinion.last

              expect(opinion).to be_authored_by(author)
              expect(opinion.identities).to include(user_group)
            end
          end

          context "with extra hashtags" do
            let(:suggested_hashtags) { %w(Hashtag1 Hashtag2) }

            it "saves the extra hashtags" do
              command.call
              opinion = Decidim::Opinions::Opinion.last
              expect(opinion.body).to include("_Hashtag1")
              expect(opinion.body).to include("_Hashtag2")
            end
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
        end
      end
    end
  end
end
