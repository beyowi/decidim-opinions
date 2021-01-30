# frozen_string_literal: true

class AddIndexCreatedAtOpinionNotes < ActiveRecord::Migration[5.1]
  def change
    add_index :decidim_opinions_opinion_notes, :created_at
  end
end
