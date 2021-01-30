# frozen_string_literal: true

class AddPositionToOpinions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_opinions_opinions, :position, :integer
  end
end
