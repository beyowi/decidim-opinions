# frozen_string_literal: true

class AddCostsToOpinions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_opinions_opinions, :cost, :decimal
    add_column :decidim_opinions_opinions, :cost_report, :jsonb
    add_column :decidim_opinions_opinions, :execution_period, :jsonb
  end
end
