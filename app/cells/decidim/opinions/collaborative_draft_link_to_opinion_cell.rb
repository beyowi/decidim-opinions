# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Opinions
    # This cell renders the link to the published opinion of a collaborative draft.
    class CollaborativeDraftLinkToOpinionCell < Decidim::ViewModel
      def show
        render if opinion
      end

      private

      def opinion
        @opinion ||= model.linked_resources(:opinion, "created_from_collaborative_draft").first
      end

      def link_to_resource
        link_to resource_locator(opinion).path, class: "button secondary light expanded button--sc mt-s" do
          t("published_opinion", scope: "decidim.opinions.collaborative_drafts.show")
        end
      end

      def link_header
        content_tag :strong, class: "text-large" do
          t("final_opinion", scope: "decidim.opinions.collaborative_drafts.show")
        end
      end

      def link_help_text
        content_tag :span, class: "text-medium" do
          t("final_opinion_help_text", scope: "decidim.opinions.collaborative_drafts.show")
        end
      end

      def link_to_versions
        @path ||= decidim_opinions.collaborative_draft_versions_path(
          collaborative_draft_id: model.id
        )
        link_to @path, class: "text-medium" do
          content_tag :u do
            t("version_history", scope: "decidim.opinions.collaborative_drafts.show")
          end
        end
      end

      def decidim
        Decidim::Core::Engine.routes.url_helpers
      end

      def decidim_opinions
        Decidim::EngineRouter.main_proxy(model.component)
      end
    end
  end
end
