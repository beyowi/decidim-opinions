# frozen_string_literal: true

class AddCreatedInMeeting < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_opinions_opinions, :created_in_meeting, :boolean, default: false
  end
end
