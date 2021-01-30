# frozen_string_literal: true

class AddHiddenAtToOpinions < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_opinions_opinions, :hidden_at, :datetime
  end
end
