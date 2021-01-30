# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe UpdateOpinionScope do
        describe "call" do
          let!(:opinion) { create :opinion }
          let!(:opinions) { create_list(:opinion, 3, component: opinion.component) }
          let!(:scope_one) { create :scope, organization: opinion.organization }
          let!(:scope) { create :scope, organization: opinion.organization }

          context "with no scope" do
            it "broadcasts invalid_scope" do
              expect { described_class.call(nil, opinion.id) }.to broadcast(:invalid_scope)
            end
          end

          context "with no opinions" do
            it "broadcasts invalid_opinion_ids" do
              expect { described_class.call(scope.id, nil) }.to broadcast(:invalid_opinion_ids)
            end
          end

          describe "with a scope and opinions" do
            context "when the scope is the same as the opinion's scope" do
              before do
                opinion.update!(scope: scope)
              end

              it "doesn't update the opinion" do
                expect(opinion).not_to receive(:update!)
                described_class.call(opinion.scope.id, opinion.id)
              end
            end

            context "when the scope is diferent from the opinion's scope" do
              before do
                opinions.each { |p| p.update!(scope: scope_one) }
              end

              it "broadcasts update_opinions_scope" do
                expect { described_class.call(scope.id, opinions.pluck(:id)) }.to broadcast(:update_opinions_scope)
              end

              it "updates the opinion" do
                described_class.call(scope.id, opinion.id)

                expect(opinion.reload.scope).to eq(scope)
              end
            end
          end
        end
      end
    end
  end
end
