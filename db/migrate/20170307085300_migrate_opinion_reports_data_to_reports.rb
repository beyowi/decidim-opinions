# frozen_string_literal: true

class MigrateOpinionReportsDataToReports < ActiveRecord::Migration[5.0]
  class Decidim::Opinions::OpinionReport < ApplicationRecord
    belongs_to :user, foreign_key: "decidim_user_id", class_name: "Decidim::User"
    belongs_to :opinion, foreign_key: "decidim_opinion_id", class_name: "Decidim::Opinions::Opinion"
  end

  def change
    Decidim::Opinions::OpinionReport.find_each do |opinion_report|
      moderation = Decidim::Moderation.find_or_create_by!(reportable: opinion_report.opinion,
                                                          participatory_process: opinion_report.opinion.feature.participatory_space)
      Decidim::Report.create!(moderation: moderation,
                              user: opinion_report.user,
                              reason: opinion_report.reason,
                              details: opinion_report.details)
      moderation.update!(report_count: moderation.report_count + 1)
    end

    drop_table :decidim_opinions_opinion_reports
    remove_column :decidim_opinions_opinions, :report_count
    remove_column :decidim_opinions_opinions, :hidden_at
  end
end
