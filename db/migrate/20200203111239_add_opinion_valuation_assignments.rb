# frozen_string_literal: true

class AddOpinionValuationAssignments < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_opinions_valuation_assignments do |t|
      t.references :decidim_opinion, null: false, index: { name: "decidim_opinions_valuation_assignment_opinion" }
      t.references :valuator_role, polymorphic: true, null: false, index: { name: "decidim_opinions_valuation_assignment_valuator_role" }

      t.timestamps
    end
  end
end
