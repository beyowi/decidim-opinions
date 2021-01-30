# frozen_string_literal: true

class AddPublishedAtToOpinions < ActiveRecord::Migration[5.1]
  def up
    add_column :decidim_opinions_opinions, :published_at, :datetime, index: true
    # rubocop:disable Rails/SkipsModelValidations
    Decidim::Opinions::Opinion.update_all("published_at = updated_at")
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    remove_column :decidim_opinions_opinions, :published_at
  end
end
