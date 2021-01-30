# frozen_string_literal: true

class UseMd5Indexes < ActiveRecord::Migration[5.2]
  def up
    remove_index :decidim_opinions_opinions, name: "decidim_opinions_opinion_title_search"
    remove_index :decidim_opinions_opinions, name: "decidim_opinions_opinion_body_search"
    execute "CREATE INDEX decidim_opinions_opinion_title_search ON decidim_opinions_opinions(md5(title::text))"
    execute "CREATE INDEX decidim_opinions_opinion_body_search ON decidim_opinions_opinions(md5(body::text))"
  end

  def down
    remove_index :decidim_opinions_opinions, name: "decidim_opinions_opinion_title_search"
    remove_index :decidim_opinions_opinions, name: "decidim_opinions_opinion_body_search"
    add_index :decidim_opinions_opinions, :title, name: "decidim_opinions_opinion_title_search"
    add_index :decidim_opinions_opinions, :body, name: "decidim_opinions_opinion_body_search"
  end
end
