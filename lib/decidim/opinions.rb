# frozen_string_literal: true

require "decidim/opinions/admin"
require "decidim/opinions/engine"
require "decidim/opinions/admin_engine"
require "decidim/opinions/component"
require "acts_as_list"

module Decidim
  # This namespace holds the logic of the `Opinions` component. This component
  # allows users to create opinions in a participatory process.
  module Opinions
    autoload :OpinionSerializer, "decidim/opinions/opinion_serializer"
    autoload :CommentableOpinion, "decidim/opinions/commentable_opinion"
    autoload :CommentableCollaborativeDraft, "decidim/opinions/commentable_collaborative_draft"
    autoload :MarkdownToOpinions, "decidim/opinions/markdown_to_opinions"
    autoload :ParticipatoryTextSection, "decidim/opinions/participatory_text_section"
    autoload :DocToMarkdown, "decidim/opinions/doc_to_markdown"
    autoload :OdtToMarkdown, "decidim/opinions/odt_to_markdown"
    autoload :Valuatable, "decidim/opinions/valuatable"

    include ActiveSupport::Configurable

    # Public Setting that defines the similarity minimum value to consider two
    # opinions similar. Defaults to 0.25.
    config_accessor :similarity_threshold do
      0.25
    end

    # Public Setting that defines how many similar opinions will be shown.
    # Defaults to 10.
    config_accessor :similarity_limit do
      10
    end

    # Public Setting that defines how many opinions will be shown in the
    # participatory_space_highlighted_elements view hook
    config_accessor :participatory_space_highlighted_opinions_limit do
      4
    end

    # Public Setting that defines how many opinions will be shown in the
    # process_group_highlighted_elements view hook
    config_accessor :process_group_highlighted_opinions_limit do
      3
    end
  end

  module ContentParsers
    autoload :OpinionParser, "decidim/content_parsers/opinion_parser"
  end

  module ContentRenderers
    autoload :OpinionRenderer, "decidim/content_renderers/opinion_renderer"
  end
end
