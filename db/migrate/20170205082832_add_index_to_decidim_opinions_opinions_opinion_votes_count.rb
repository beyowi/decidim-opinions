# frozen_string_literal: true

class AddIndexToDecidimOpinionsOpinionsOpinionVotesCount < ActiveRecord::Migration[5.0]
  def change
    add_index :decidim_opinions_opinions, :opinion_votes_count
    add_index :decidim_opinions_opinions, :created_at
    add_index :decidim_opinions_opinions, :state
  end
end
