# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe PublishParticipatoryText do
        describe "call" do
          let(:current_component) do
            create(
              :opinion_component,
              participatory_space: create(:participatory_process)
            )
          end
          let(:opinions) do
            opinions = create_list(:opinion, 3, :draft, component: current_component)
            opinions.each_with_index do |opinion, idx|
              level = Decidim::Opinions::ParticipatoryTextSection::LEVELS.keys[idx]
              opinion.update(participatory_text_level: level)
              opinion.versions.destroy_all
            end
            opinions
          end
          let(:opinion_modifications) do
            modifs = []
            new_positions = [3, 1, 2]
            opinions.each do |opinion|
              modifs << Decidim::Opinions::Admin::OpinionForm.new(
                id: opinion.id,
                position: new_positions.shift,
                title: ::Faker::Books::Lovecraft.fhtagn,
                body: ::Faker::Books::Lovecraft.fhtagn(5)
              )
            end
            modifs
          end
          let(:form) do
            instance_double(
              PreviewParticipatoryTextForm,
              current_component: current_component,
              current_user: create(:user, organization: current_component.organization),
              opinions: opinion_modifications
            )
          end
          let!(:command) { described_class.new(form) }

          it "creates a version for each opinion", versioning: true do
            expect { command.call }.to broadcast(:ok)

            opinions.each do |opinion|
              expect(opinion.reload.versions.count).to eq(1)
            end
          end

          describe "when form modifies opinions" do
            context "with valid values" do
              it "persists modifications" do
                expect { command.call }.to broadcast(:ok)
                opinions.zip(opinion_modifications).each do |opinion, opinion_form|
                  opinion.reload
                  actual = {}
                  expected = {}
                  %w(position title body).each do |attr|
                    next if (attr == "body") && (opinion.participatory_text_level != Decidim::Opinions::ParticipatoryTextSection::LEVELS[:article])

                    expected[attr] = opinion_form.send attr.to_sym
                    actual[attr] = opinion.attributes[attr]
                  end
                  expect(actual).to eq(expected)
                end
              end
            end

            context "with invalid values" do
              before do
                opinion_modifications.each { |opinion_form| opinion_form.title = "" }
              end

              it "does not persist modifications and broadcasts invalid" do
                failures = {}
                opinions.each do |opinion|
                  failures[opinion.id] = ["Title can't be blank"]
                end
                expect { command.call }.to broadcast(:invalid, failures)
              end
            end
          end
        end
      end
    end
  end
end
