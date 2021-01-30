# frozen_string_literal: true

class AddUserGroupIdToOpinions < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_opinions_opinions, :decidim_user_group_id, :integer, index: true
  end
end
