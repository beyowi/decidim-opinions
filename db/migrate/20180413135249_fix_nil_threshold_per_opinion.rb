# frozen_string_literal: true

class FixNilThresholdPerOpinion < ActiveRecord::Migration[5.1]
  class Component < ApplicationRecord
    self.table_name = :decidim_components
  end

  def change
    opinion_components = Component.where(manifest_name: "opinions")

    opinion_components.each do |component|
      settings = component.attributes["settings"]
      settings["global"]["threshold_per_opinion"] ||= 0
      component.settings = settings
      component.save
    end
  end
end
