# frozen_string_literal: true

class AddReportCountToOpinions < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_opinions_opinions, :report_count, :integer, default: 0
  end
end
