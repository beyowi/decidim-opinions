# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Opinions
    module Admin
      describe DiscardParticipatoryText do
        describe "call" do
          let(:current_component) do
            create(
              :opinion_component,
              participatory_space: create(:participatory_process)
            )
          end
          let(:opinions) do
            create_list(:opinion, 3, :draft, component: current_component)
          end
          let(:command) { described_class.new(current_component) }

          describe "when discarding" do
            it "removes all drafts" do
              expect { command.call }.to broadcast(:ok)
              opinions = Decidim::Opinions::Opinion.drafts.where(component: current_component)
              expect(opinions).to be_empty
            end
          end
        end
      end
    end
  end
end
