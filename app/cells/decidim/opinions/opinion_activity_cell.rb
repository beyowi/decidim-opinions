# frozen_string_literal: true

module Decidim
  module Opinions
    # A cell to display when a opinion has been published.
    class OpinionActivityCell < ActivityCell
      def title
        I18n.t(
          "decidim.opinions.last_activity.new_opinion_at_html",
          link: participatory_space_link
        )
      end

      def resource_link_text
        decidim_html_escape(presenter.title)
      end

      def description
        strip_tags(presenter.body(links: true))
      end

      def presenter
        @presenter ||= Decidim::Opinions::OpinionPresenter.new(resource)
      end
    end
  end
end
