# frozen_string_literal: true

class CreateDecidimOpinionNotes < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_opinions_opinion_notes do |t|
      t.references :decidim_opinion, null: false, index: { name: "decidim_opinions_opinion_note_opinion" }
      t.references :decidim_author, null: false, index: { name: "decidim_opinions_opinion_note_author" }
      t.text :body, null: false

      t.timestamps
    end

    add_column :decidim_opinions_opinions, :opinion_notes_count, :integer, null: false, default: 0
  end
end
