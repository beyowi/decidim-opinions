# frozen_string_literal: true

class AddCounterCacheEndorsementsToOpinions < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_opinions_opinions, :opinion_endorsements_count, :integer, null: false, default: 0
    add_index :decidim_opinions_opinions, :opinion_endorsements_count, name: "idx_decidim_opinions_opinions_on_opinion_endorsemnts_count"
  end
end
