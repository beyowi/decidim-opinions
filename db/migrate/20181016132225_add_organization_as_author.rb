# frozen_string_literal: true

class AddOrganizationAsAuthor < ActiveRecord::Migration[5.2]
  def change
    official_opinions = Decidim::Opinions::Opinion.find_each.select do |opinion|
      opinion.coauthorships.count.zero?
    end

    official_opinions.each do |opinion|
      opinion.add_coauthor(opinion.organization)
    end
  end
end
