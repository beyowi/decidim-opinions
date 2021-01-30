# frozen_string_literal: true

class CreateOpinionReports < ActiveRecord::Migration[5.0]
  def change
    create_table :decidim_opinions_opinion_reports do |t|
      t.references :decidim_opinion, null: false, index: { name: "decidim_opinions_opinion_result_opinion" }
      t.references :decidim_user, null: false, index: { name: "decidim_opinions_opinion_result_user" }
      t.string :reason, null: false
      t.text :details

      t.timestamps
    end

    add_index :decidim_opinions_opinion_reports, [:decidim_opinion_id, :decidim_user_id], unique: true, name: "decidim_opinions_opinion_report_opinion_user_unique"
  end
end
