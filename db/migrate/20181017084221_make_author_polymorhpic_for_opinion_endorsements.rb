# frozen_string_literal: true

class MakeAuthorPolymorhpicForOpinionEndorsements < ActiveRecord::Migration[5.2]
  class OpinionEndorsement < ApplicationRecord
    self.table_name = :decidim_opinions_opinion_endorsements
  end

  def change
    remove_index :decidim_opinions_opinion_endorsements, :decidim_author_id

    add_column :decidim_opinions_opinion_endorsements, :decidim_author_type, :string

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE decidim_opinions_opinion_endorsements
          SET decidim_author_type = 'Decidim::UserBaseEntity'
        SQL
      end
    end

    add_index :decidim_opinions_opinion_endorsements,
              [:decidim_author_id, :decidim_author_type],
              name: "index_decidim_opinions_opinion_endorsements_on_decidim_author"

    change_column_null :decidim_opinions_opinion_endorsements, :decidim_author_id, false
    change_column_null :decidim_opinions_opinion_endorsements, :decidim_author_type, false

    OpinionEndorsement.reset_column_information
  end
end
