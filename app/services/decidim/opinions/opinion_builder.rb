# frozen_string_literal: true

require "open-uri"

module Decidim
  module Opinions
    # A factory class to ensure we always create Opinions the same way since it involves some logic.
    module OpinionBuilder
      # Public: Creates a new Opinion.
      #
      # attributes        - The Hash of attributes to create the Opinion with.
      # author            - An Authorable the will be the first coauthor of the Opinion.
      # user_group_author - A User Group to, optionally, set it as the author too.
      # action_user       - The User to be used as the user who is creating the opinion in the traceability logs.
      #
      # Returns a Opinion.
      def create(attributes:, author:, action_user:, user_group_author: nil)
        Decidim.traceability.perform_action!(:create, Opinion, action_user, visibility: "all") do
          opinion = Opinion.new(attributes)
          opinion.add_coauthor(author, user_group: user_group_author)
          opinion.save!
          opinion
        end
      end

      module_function :create

      # Public: Creates a new Opinion with the authors of the `original_opinion`.
      #
      # attributes - The Hash of attributes to create the Opinion with.
      # action_user - The User to be used as the user who is creating the opinion in the traceability logs.
      # original_opinion - The opinion from which authors will be copied.
      #
      # Returns a Opinion.
      def create_with_authors(attributes:, action_user:, original_opinion:)
        Decidim.traceability.perform_action!(:create, Opinion, action_user, visibility: "all") do
          opinion = Opinion.new(attributes)
          original_opinion.coauthorships.each do |coauthorship|
            opinion.add_coauthor(coauthorship.author, user_group: coauthorship.user_group)
          end
          opinion.save!
          opinion
        end
      end

      module_function :create_with_authors

      # Public: Creates a new Opinion by copying the attributes from another one.
      #
      # original_opinion - The Opinion to be used as base to create the new one.
      # author            - An Authorable the will be the first coauthor of the Opinion.
      # user_group_author - A User Group to, optionally, set it as the author too.
      # action_user       - The User to be used as the user who is creating the opinion in the traceability logs.
      # extra_attributes  - A Hash of attributes to create the new opinion, will overwrite the original ones.
      # skip_link         - Whether to skip linking the two opinions or not (default false).
      #
      # Returns a Opinion
      #
      # rubocop:disable Metrics/ParameterLists
      def copy(original_opinion, author:, action_user:, user_group_author: nil, extra_attributes: {}, skip_link: false)
        origin_attributes = original_opinion.attributes.except(
          "id",
          "created_at",
          "updated_at",
          "state",
          "answer",
          "answered_at",
          "decidim_component_id",
          "reference",
          "opinion_votes_count",
          "endorsements_count",
          "opinion_notes_count"
        ).merge(
          "category" => original_opinion.category
        ).merge(
          extra_attributes
        )

        opinion = if author.nil?
                     create_with_authors(
                       attributes: origin_attributes,
                       original_opinion: original_opinion,
                       action_user: action_user
                     )
                   else
                     create(
                       attributes: origin_attributes,
                       author: author,
                       user_group_author: user_group_author,
                       action_user: action_user
                     )
                   end

        opinion.link_resources(original_opinion, "copied_from_component") unless skip_link
        copy_attachments(original_opinion, opinion)

        opinion
      end
      # rubocop:enable Metrics/ParameterLists

      module_function :copy

      def copy_attachments(original_opinion, opinion)
        original_opinion.attachments.each do |attachment|
          new_attachment = Decidim::Attachment.new(attachment.attributes.slice("content_type", "description", "file", "file_size", "title", "weight"))
          new_attachment.attached_to = opinion

          if File.exist?(attachment.file.file.path)
            new_attachment.file = File.open(attachment.file.file.path)
          else
            new_attachment.remote_file_url = attachment.url
          end

          new_attachment.save!
        rescue Errno::ENOENT, OpenURI::HTTPError => e
          Rails.logger.warn("[ERROR] Couldn't copy attachment from opinion #{original_opinion.id} when copying to component due to #{e.message}")
        end
      end

      module_function :copy_attachments
    end
  end
end
