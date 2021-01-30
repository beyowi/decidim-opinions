# frozen_string_literal: true

class CreateOpinionEndorsements < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_opinions_opinion_endorsements do |t|
      t.references :decidim_opinion, null: false, index: { name: "decidim_opinions_opinion_endorsement_opinion" }
      t.references :decidim_author, null: false, index: { name: "decidim_opinions_opinion_endorsement_author" }
      t.references :decidim_user_group, null: true, index: { name: "decidim_opinions_opinion_endorsement_user_group" }

      t.timestamps
    end

    add_index :decidim_opinions_opinion_endorsements, "decidim_opinion_id, decidim_author_id, (coalesce(decidim_user_group_id,-1))", unique: true, name:
      "decidim_opinions_opinion_endorsmt_opinion_auth_ugroup_uniq"
  end
end
