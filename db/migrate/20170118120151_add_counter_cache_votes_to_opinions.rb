# frozen_string_literal: true

class AddCounterCacheVotesToOpinions < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_opinions_opinions, :opinion_votes_count, :integer, null: false, default: 0
  end
end
