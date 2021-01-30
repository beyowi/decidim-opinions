# frozen_string_literal: true

class AddCounterCacheCoauthorshipsToCollaborativeDrafts < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_opinions_collaborative_drafts, :coauthorships_count, :integer, null: false, default: 0
  end
end
