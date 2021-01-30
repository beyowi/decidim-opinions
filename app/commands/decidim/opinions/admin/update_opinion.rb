# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A command with all the business logic when a user updates a opinion.
      class UpdateOpinion < Rectify::Command
        include ::Decidim::AttachmentMethods
        include GalleryMethods
        include HashtagsMethods

        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # opinion - the opinion to update.
        def initialize(form, opinion)
          @form = form
          @opinion = opinion
          @attached_to = opinion
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the opinion.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          if process_attachments?
            @opinion.attachments.destroy_all

            build_attachment
            return broadcast(:invalid) if attachment_invalid?
          end

          if process_gallery?
            build_gallery
            return broadcast(:invalid) if gallery_invalid?
          end

          transaction do
            update_opinion
            update_opinion_author
            create_attachment if process_attachments?
            create_gallery if process_gallery?
            photo_cleanup!
          end

          broadcast(:ok, opinion)
        end

        private

        attr_reader :form, :opinion, :attachment, :gallery

        def update_opinion
          Decidim.traceability.update!(
            opinion,
            form.current_user,
            title: title_with_hashtags,
            body: body_with_hashtags,
            category: form.category,
            scope: form.scope,
            address: form.address,
            latitude: form.latitude,
            longitude: form.longitude,
            created_in_meeting: form.created_in_meeting
          )
        end

        def update_opinion_author
          opinion.coauthorships.clear
          opinion.add_coauthor(form.author)
          opinion.save!
          opinion
        end
      end
    end
  end
end
