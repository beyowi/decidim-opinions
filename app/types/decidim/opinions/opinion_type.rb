# frozen_string_literal: true

module Decidim
  module Opinions
    OpinionType = GraphQL::ObjectType.define do
      name "Opinion"
      description "A opinion"

      interfaces [
        -> { Decidim::Comments::CommentableInterface },
        -> { Decidim::Core::CoauthorableInterface },
        -> { Decidim::Core::CategorizableInterface },
        -> { Decidim::Core::ScopableInterface },
        -> { Decidim::Core::AttachableInterface },
        -> { Decidim::Core::FingerprintInterface },
        -> { Decidim::Core::AmendableInterface },
        -> { Decidim::Core::AmendableEntityInterface },
        -> { Decidim::Core::TraceableInterface },
        -> { Decidim::Core::EndorsableInterface },
        -> { Decidim::Core::TimestampsInterface }
      ]

      field :id, !types.ID
      field :title, !types.String, "This opinion's title"
      field :body, types.String, "This opinion's body"
      field :address, types.String, "The physical address (location) of this opinion"
      field :coordinates, Decidim::Core::CoordinatesType, "Physical coordinates for this opinion" do
        resolve ->(opinion, _args, _ctx) {
          [opinion.latitude, opinion.longitude]
        }
      end
      field :reference, types.String, "This opinion's unique reference"
      field :state, types.String, "The answer status in which opinion is in"
      field :answer, Decidim::Core::TranslatedFieldType, "The answer feedback for the status for this opinion"

      field :answeredAt, Decidim::Core::DateTimeType do
        description "The date and time this opinion was answered"
        property :answered_at
      end

      field :publishedAt, Decidim::Core::DateTimeType do
        description "The date and time this opinion was published"
        property :published_at
      end

      field :participatoryTextLevel, types.String do
        description "If it is a participatory text, the level indicates the type of paragraph"
        property :participatory_text_level
      end
      field :position, types.Int, "Position of this opinion in the participatory text"

      field :official, types.Boolean, "Whether this opinion is official or not", property: :official?
      field :createdInMeeting, types.Boolean, "Whether this opinion comes from a meeting or not", property: :official_meeting?
      field :meeting, Decidim::Meetings::MeetingType do
        description "If the opinion comes from a meeting, the related meeting"
        resolve ->(opinion, _, _) {
          opinion.authors.first if opinion.official_meeting?
        }
      end

      field :voteCount, types.Int do
        description "The total amount of votes the opinion has received"
        resolve ->(opinion, _args, _ctx) {
          current_component = opinion.component
          opinion.opinion_votes_count unless current_component.current_settings.votes_hidden?
        }
      end
    end
  end
end
