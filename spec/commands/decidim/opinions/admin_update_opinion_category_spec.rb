# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe UpdateOpinionCategory do
        describe "call" do
          let(:organization) { create(:organization) }

          let!(:opinion) { create :opinion }
          let!(:opinions) { create_list(:opinion, 3, component: opinion.component) }
          let!(:category_one) { create :category, participatory_space: opinion.component.participatory_space }
          let!(:category) { create :category, participatory_space: opinion.component.participatory_space }

          context "with no category" do
            it "broadcasts invalid_category" do
              expect { described_class.call(nil, opinion.id) }.to broadcast(:invalid_category)
            end
          end

          context "with no opinions" do
            it "broadcasts invalid_opinion_ids" do
              expect { described_class.call(category.id, nil) }.to broadcast(:invalid_opinion_ids)
            end
          end

          describe "with a category and opinions" do
            context "when the category is the same as the opinion's category" do
              before do
                opinion.update!(category: category)
              end

              it "doesn't update the opinion" do
                expect(opinion).not_to receive(:update!)
                described_class.call(opinion.category.id, opinion.id)
              end
            end

            context "when the category is diferent from the opinion's category" do
              before do
                opinions.each { |p| p.update!(category: category_one) }
              end

              it "broadcasts update_opinions_category" do
                expect { described_class.call(category.id, opinions.pluck(:id)) }.to broadcast(:update_opinions_category)
              end

              it "updates the opinion" do
                described_class.call(category.id, opinion.id)

                expect(opinion.reload.category).to eq(category)
              end
            end
          end
        end
      end
    end
  end
end
