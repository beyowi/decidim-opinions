# frozen_string_literal: true

module Decidim
  module Opinions
    # A command with all the business logic when a user destroys a draft opinion.
    class DestroyOpinion < Rectify::Command
      # Public: Initializes the command.
      #
      # opinion     - The opinion to destroy.
      # current_user - The current user.
      def initialize(opinion, current_user)
        @opinion = opinion
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the opinion is deleted.
      # - :invalid if the opinion is not a draft.
      # - :invalid if the opinion's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) unless @opinion.draft?
        return broadcast(:invalid) unless @opinion.authored_by?(@current_user)

        @opinion.destroy!

        broadcast(:ok, @opinion)
      end
    end
  end
end
