# frozen_string_literal: true

module Decidim
  module Opinions
    # A command with all the business logic when a user creates a new opinion.
    class CreateOpinion < Rectify::Command
      include ::Decidim::AttachmentMethods
      include HashtagsMethods

      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # coauthorships - The coauthorships of the opinion.
      def initialize(form, current_user, coauthorships = nil)
        @form = form
        @current_user = current_user
        @coauthorships = coauthorships
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the opinion.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        if opinion_limit_reached?
          form.errors.add(:base, I18n.t("decidim.opinions.new.limit_reached"))
          return broadcast(:invalid)
        end

        transaction do
          create_opinion
        end

        broadcast(:ok, opinion)
      end

      private

      attr_reader :form, :opinion, :attachment

      # Prevent PaperTrail from creating an additional version
      # in the opinion multi-step creation process (step 1: create)
      #
      # A first version will be created in step 4: publish
      # for diff rendering in the opinion version control
      def create_opinion
        PaperTrail.request(enabled: false) do
          @opinion = Decidim.traceability.perform_action!(
            :create,
            Decidim::Opinions::Opinion,
            @current_user,
            visibility: "public-only"
          ) do
            opinion = Opinion.new(
              title: title_with_hashtags,
              body: body_with_hashtags,
              component: form.component
            )
            opinion.add_coauthor(@current_user, user_group: user_group)
            opinion.save!
            opinion
          end
        end
      end

      def opinion_limit_reached?
        return false if @coauthorships.present?

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
        @organization ||= @current_user.organization
      end

      def current_user_opinions
        Opinion.from_author(@current_user).where(component: form.current_component).except_withdrawn
      end

      def user_group_opinions
        Opinion.from_user_group(@user_group).where(component: form.current_component).except_withdrawn
      end
    end
  end
end
