# frozen_string_literal: true

class AddStatePublishedAtToOpinions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_opinions_opinions, :state_published_at, :datetime
  end
end
