# frozen_string_literal: true

module Decidim
  module Opinions
    # This class serializes a Opinion so can be exported to CSV, JSON or other
    # formats.
    class OpinionSerializer < Decidim::Exporters::Serializer
      include Decidim::ApplicationHelper
      include Decidim::ResourceHelper
      include Decidim::TranslationsHelper

      # Public: Initializes the serializer with a opinion.
      def initialize(opinion)
        @opinion = opinion
      end

      # Public: Exports a hash with the serialized data for this opinion.
      def serialize
        {
          id: opinion.id,
          category: {
            id: opinion.category.try(:id),
            name: opinion.category.try(:name) || empty_translatable
          },
          scope: {
            id: opinion.scope.try(:id),
            name: opinion.scope.try(:name) || empty_translatable
          },
          participatory_space: {
            id: opinion.participatory_space.id,
            url: Decidim::ResourceLocatorPresenter.new(opinion.participatory_space).url
          },
          component: { id: component.id },
          title: present(opinion).title,
          body: present(opinion).body,
          state: opinion.state.to_s,
          reference: opinion.reference,
          answer: ensure_translatable(opinion.answer),
          supports: opinion.opinion_votes_count,
          endorsements: {
            total_count: opinion.endorsements.count,
            user_endorsements: user_endorsements
          },
          comments: opinion.comments.count,
          attachments: opinion.attachments.count,
          followers: opinion.followers.count,
          published_at: opinion.published_at,
          url: url,
          meeting_urls: meetings,
          related_opinions: related_opinions,
          is_amend: opinion.emendation?,
          original_opinion: {
            title: opinion&.amendable&.title,
            url: original_opinion_url
          }
        }
      end

      private

      attr_reader :opinion

      def component
        opinion.component
      end

      def meetings
        opinion.linked_resources(:meetings, "opinions_from_meeting").map do |meeting|
          Decidim::ResourceLocatorPresenter.new(meeting).url
        end
      end

      def related_opinions
        opinion.linked_resources(:opinions, "copied_from_component").map do |opinion|
          Decidim::ResourceLocatorPresenter.new(opinion).url
        end
      end

      def url
        Decidim::ResourceLocatorPresenter.new(opinion).url
      end

      def user_endorsements
        opinion.endorsements.for_listing.map { |identity| identity.normalized_author&.name }
      end

      def original_opinion_url
        return unless opinion.emendation? && opinion.amendable.present?

        Decidim::ResourceLocatorPresenter.new(opinion.amendable).url
      end
    end
  end
end
