# frozen_string_literal: true

# This migration must be executed after CreateDecidimEndorsements migration in decidim-core.
class MoveOpinionEndorsementsToCoreEndorsements < ActiveRecord::Migration[5.2]
  class OpinionEndorsement < ApplicationRecord
    self.table_name = :decidim_opinions_opinion_endorsements
  end
  class Endorsement < ApplicationRecord
    self.table_name = :decidim_endorsements
  end
  # Move OpinionEndorsements to Endorsements
  def up
    non_duplicated_group_endorsements = OpinionEndorsement.select(
      "MIN(id) as id, decidim_user_group_id"
    ).group(:decidim_user_group_id).where.not(decidim_user_group_id: nil).map(&:id)

    OpinionEndorsement.where("id IN (?) OR decidim_user_group_id IS NULL", non_duplicated_group_endorsements).find_each do |prop_endorsement|
      Endorsement.create!(
        resource_type: Decidim::Opinions::Opinion.name,
        resource_id: prop_endorsement.decidim_opinion_id,
        decidim_author_type: prop_endorsement.decidim_author_type,
        decidim_author_id: prop_endorsement.decidim_author_id,
        decidim_user_group_id: prop_endorsement.decidim_user_group_id
      )
    end
    # update new `decidim_opinions_opinion.endorsements_count` counter cache
    Decidim::Opinions::Opinion.select(:id).all.find_each do |opinion|
      Decidim::Opinions::Opinion.reset_counters(opinion.id, :endorsements)
    end
  end

  def down
    non_duplicated_group_endorsements = Endorsement.select(
      "MIN(id) as id, decidim_user_group_id"
    ).group(:decidim_user_group_id).where.not(decidim_user_group_id: nil).map(&:id)

    Endorsement
      .where(resource_type: "Decidim::Opinions::Opinion")
      .where("id IN (?) OR decidim_user_group_id IS NULL", non_duplicated_group_endorsements).find_each do |endorsement|
      OpinionEndorsement.find_or_create_by!(
        decidim_opinion_id: endorsement.resource_id,
        decidim_author_type: endorsement.decidim_author_type,
        decidim_author_id: endorsement.decidim_author_id,
        decidim_user_group_id: endorsement.decidim_user_group_id
      )
    end
    # update `decidim_opinions_opinion.opinion_endorsements_count` counter cache
    Decidim::Opinions::Opinion.select(:id).all.find_each do |opinion|
      Decidim::Opinions::Opinion.reset_counters(opinion.id, :opinion_endorsements)
    end
  end
end
