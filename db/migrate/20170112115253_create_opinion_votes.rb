# frozen_string_literal: true

class CreateOpinionVotes < ActiveRecord::Migration[5.0]
  def change
    create_table :decidim_opinions_opinion_votes do |t|
      t.references :decidim_opinion, null: false, index: { name: "decidim_opinions_opinion_vote_opinion" }
      t.references :decidim_author, null: false, index: { name: "decidim_opinions_opinion_vote_author" }

      t.timestamps
    end

    add_index :decidim_opinions_opinion_votes, [:decidim_opinion_id, :decidim_author_id], unique: true, name: "decidim_opinions_opinion_vote_opinion_author_unique"
  end
end
