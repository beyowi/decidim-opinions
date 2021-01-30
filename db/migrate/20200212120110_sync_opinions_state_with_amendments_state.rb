# frozen_string_literal: true

class SyncOpinionsStateWithAmendmentsState < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL.squish
      UPDATE decidim_opinions_opinions AS opinions
      SET state = amendments.state
      FROM decidim_amendments AS amendments
      WHERE
        opinions.state IS NULL AND
        amendments.decidim_emendation_type = 'Decidim::Opinions::Opinion' AND
        amendments.decidim_emendation_id = opinions.id AND
        amendments.state IS NOT NULL
    SQL
  end

  def down
    execute <<-SQL.squish
      UPDATE decidim_opinions_opinions AS opinions
      SET state = NULL
      FROM decidim_amendments AS amendments
      WHERE
        amendments.decidim_emendation_type = 'Decidim::Opinions::Opinion' AND
        amendments.decidim_emendation_id = opinions.id AND
        amendments.state IS NOT NULL
    SQL
  end
end
