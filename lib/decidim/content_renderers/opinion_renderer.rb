# frozen_string_literal: true

module Decidim
  module ContentRenderers
    # A renderer that searches Global IDs representing opinions in content
    # and replaces it with a link to their show page.
    #
    # e.g. gid://<APP_NAME>/Decidim::Opinions::Opinion/1
    #
    # @see BaseRenderer Examples of how to use a content renderer
    class OpinionRenderer < BaseRenderer
      # Matches a global id representing a Decidim::User
      GLOBAL_ID_REGEX = %r{gid:\/\/([\w-]*\/Decidim::Opinions::Opinion\/(\d+))}i.freeze

      # Replaces found Global IDs matching an existing opinion with
      # a link to its show page. The Global IDs representing an
      # invalid Decidim::Opinions::Opinion are replaced with '???' string.
      #
      # @return [String] the content ready to display (contains HTML)
      def render
        content.gsub(GLOBAL_ID_REGEX) do |opinion_gid|
          opinion = GlobalID::Locator.locate(opinion_gid)
          Decidim::Opinions::OpinionPresenter.new(opinion).display_mention
        rescue ActiveRecord::RecordNotFound
          opinion_id = opinion_gid.split("/").last
          "~#{opinion_id}"
        end
      end
    end
  end
end
