# frozen_string_literal: true

class AddTextSearchIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index :decidim_opinions_opinions, :title, name: "decidim_opinions_opinion_title_search"
    add_index :decidim_opinions_opinions, :body, name: "decidim_opinions_opinion_body_search"
  end
end
