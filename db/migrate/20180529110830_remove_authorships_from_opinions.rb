# frozen_string_literal: true

class RemoveAuthorshipsFromOpinions < ActiveRecord::Migration[5.1]
  def change
    remove_column :decidim_opinions_opinions, :decidim_author_id, :integer
    remove_column :decidim_opinions_opinions, :decidim_user_group_id, :integer
  end
end
