module Decidim
  module Opinions
    module AuthorCellExtend

      def creation_date?
        return true if posts_controller?
        return unless from_context
        return unless proposals_controller? || collaborative_drafts_controller? || opinions_controller?
        return unless show_action?
        true
      end

    end
  end
end

Decidim::AuthorCell.class_eval do
  prepend(Decidim::Opinions::AuthorCellExtend)
end