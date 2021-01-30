# frozen_string_literal: true

class MigrateOpinionsCategory < ActiveRecord::Migration[5.1]
  def change
    # Create categorizations ensuring database integrity
    execute('
      INSERT INTO decidim_categorizations(decidim_category_id, categorizable_id, categorizable_type, created_at, updated_at)
        SELECT decidim_category_id, decidim_opinions_opinions.id, \'Decidim::Opinions::Opinion\', NOW(), NOW()
        FROM decidim_opinions_opinions
        INNER JOIN decidim_categories ON decidim_categories.id = decidim_opinions_opinions.decidim_category_id
    ')
    # Remove unused column
    remove_column :decidim_opinions_opinions, :decidim_category_id
  end
end
