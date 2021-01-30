# frozen_string_literal: true

class AddParticipatoryTextLevelToOpinions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_opinions_opinions, :participatory_text_level, :string
  end
end
