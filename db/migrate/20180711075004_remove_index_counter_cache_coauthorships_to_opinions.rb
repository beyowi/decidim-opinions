# frozen_string_literal: true

class RemoveIndexCounterCacheCoauthorshipsToOpinions < ActiveRecord::Migration[5.2]
  def change
    remove_index :decidim_opinions_opinions, name: "idx_decidim_opinions_opinions_on_opinion_coauthorships_count"
  end
end
