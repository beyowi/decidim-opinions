# frozen_string_literal: true

class AddReferenceToOpinions < ActiveRecord::Migration[5.0]
  class Opinion < ApplicationRecord
    self.table_name = :decidim_opinions_opinions
  end

  def change
    add_column :decidim_opinions_opinions, :reference, :string
    Opinion.find_each(&:save)
    change_column_null :decidim_opinions_opinions, :reference, false
  end
end
