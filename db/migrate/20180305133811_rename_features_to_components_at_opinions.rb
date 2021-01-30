# frozen_string_literal: true

class RenameFeaturesToComponentsAtOpinions < ActiveRecord::Migration[5.1]
  def change
    rename_column :decidim_opinions_opinions, :decidim_feature_id, :decidim_component_id

    if index_name_exists?(:decidim_opinions_opinions, "index_decidim_opinions_opinions_on_decidim_feature_id")
      rename_index :decidim_opinions_opinions, "index_decidim_opinions_opinions_on_decidim_feature_id", "index_decidim_opinions_opinions_on_decidim_component_id"
    end
  end
end
