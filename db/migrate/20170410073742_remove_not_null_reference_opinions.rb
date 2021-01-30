# frozen_string_literal: true

class RemoveNotNullReferenceOpinions < ActiveRecord::Migration[5.0]
  def change
    change_column_null :decidim_opinions_opinions, :reference, true
  end
end
