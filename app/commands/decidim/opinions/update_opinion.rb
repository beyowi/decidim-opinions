# frozen_string_literal: true

module Decidim
  module Opinions
    # A command with all the business logic when a user updates a opinion.
    class UpdateOpinion < Rectify::Command
      include ::Decidim::AttachmentMethods
      include HashtagsMethods

      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # opinion - the opinion to update.
      def initialize(form, current_user, opinion)
        @form = form
        @current_user = current_user
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
        return broadcast(:invalid) unless opinion.editable_by?(current_user)
        return broadcast(:invalid) if opinion_limit_reached?

        if process_attachments?
          @opinion.attachments.destroy_all

          build_attachment
          return broadcast(:invalid) if attachment_invalid?
        end

        transaction do
          if @opinion.draft?
            update_draft
          else
            update_opinion
          end
          create_attachment if process_attachments?
        end

        broadcast(:ok, opinion)
      end

      private

      attr_reader :form, :opinion, :current_user, :attachment

      # Prevent PaperTrail from creating an additional version
      # in the opinion multi-step creation process (step 3: complete)
      #
      # A first version will be created in step 4: publish
      # for diff rendering in the opinion control version
      def update_draft
        PaperTrail.request(enabled: false) do
          @opinion.update(attributes)
          @opinion.coauthorships.clear
          @opinion.add_coauthor(current_user, user_group: user_group)
        end
      end

      def update_opinion
        @opinion = Decidim.traceability.update!(
          @opinion,
          current_user,
          attributes,
          visibility: "public-only"
        )
        @opinion.coauthorships.clear
        @opinion.add_coauthor(current_user, user_group: user_group)
      end

      def attributes
        {
          title: title_with_hashtags,
          body: body_with_hashtags,
          category: form.category,
          scope: form.scope,
          address: form.address,
          latitude: form.latitude,
          longitude: form.longitude
        }
      end

      def opinion_limit_reached?
        opinion_limit = form.current_component.settings.opinion_limit

        return false if opinion_limit.zero?

        if user_group
          user_group_opinions.count >= opinion_limit
        else
          current_user_opinions.count >= opinion_limit
        end
      end

      def user_group
        @user_group ||= Decidim::UserGroup.find_by(organization: organization, id: form.user_group_id)
      end

      def organization
        @organization ||= current_user.organization
      end

      def current_user_opinions
        Opinion.from_author(current_user).where(component: form.current_component).published.where.not(id: opinion.id).except_withdrawn
      end

      def user_group_opinions
        Opinion.from_user_group(user_group).where(component: form.current_component).published.where.not(id: opinion.id).except_withdrawn
      end
    end
  end
end
