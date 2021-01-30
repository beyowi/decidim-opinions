# frozen_string_literal: true

class AddCounterCacheCoauthorshipsToOpinions < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_opinions_opinions, :coauthorships_count, :integer, null: false, default: 0
    add_index :decidim_opinions_opinions, :coauthorships_count, name: "idx_decidim_opinions_opinions_on_opinion_coauthorships_count"
  end
end
