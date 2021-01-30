# frozen_string_literal: true

class AddAnswersToOpinions < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_opinions_opinions, :state, :string, index: true
    add_column :decidim_opinions_opinions, :answered_at, :datetime, index: true
    add_column :decidim_opinions_opinions, :answer, :jsonb
  end
end
