# frozen_string_literal: true

module Decidim
  module Opinions
    # A command with all the business logic when a user withdraws a new opinion.
    class WithdrawOpinion < Rectify::Command
      # Public: Initializes the command.
      #
      # opinion     - The opinion to withdraw.
      # current_user - The current user.
      def initialize(opinion, current_user)
        @opinion = opinion
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the opinion.
      # - :has_supports if the opinion already has supports or does not belong to current user.
      #
      # Returns nothing.
      def call
        return broadcast(:has_supports) if @opinion.votes.any?

        transaction do
          change_opinion_state_to_withdrawn
          reject_emendations_if_any
        end

        broadcast(:ok, @opinion)
      end

      private

      def change_opinion_state_to_withdrawn
        @opinion.update state: "withdrawn"
      end

      def reject_emendations_if_any
        return if @opinion.emendations.empty?

        @opinion.emendations.each do |emendation|
          @form = form(Decidim::Amendable::RejectForm).from_params(id: emendation.amendment.id)
          result = Decidim::Amendable::Reject.call(@form)
          return result[:ok] if result[:ok]
        end
      end
    end
  end
end
