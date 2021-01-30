# frozen_string_literal: true

class AddGeolocalizationFieldsToOpinions < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_opinions_opinions, :address, :text
    add_column :decidim_opinions_opinions, :latitude, :float
    add_column :decidim_opinions_opinions, :longitude, :float
  end
end
