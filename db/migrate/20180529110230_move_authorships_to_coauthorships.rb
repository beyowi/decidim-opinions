# frozen_string_literal: true

class MoveAuthorshipsToCoauthorships < ActiveRecord::Migration[5.1]
  class Opinion < ApplicationRecord
    self.table_name = :decidim_opinions_opinions
  end
  class Coauthorship < ApplicationRecord
    self.table_name = :decidim_coauthorships
  end

  def change
    opinions = Opinion.all

    opinions.each do |opinion|
      author_id = opinion.attributes["decidim_author_id"]
      user_group_id = opinion.attributes["decidim_user_group_id"]

      next if author_id.nil?

      Coauthorship.create!(
        coauthorable_id: opinion.id,
        coauthorable_type: "Decidim::Opinions::Opinion",
        decidim_author_id: author_id,
        decidim_user_group_id: user_group_id
      )
    end
  end
end
