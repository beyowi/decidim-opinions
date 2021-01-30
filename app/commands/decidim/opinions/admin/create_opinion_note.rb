# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A command with all the business logic when an admin creates a private note opinion.
      class CreateOpinionNote < Rectify::Command
        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # opinion - the opinion to relate.
        def initialize(form, opinion)
          @form = form
          @opinion = opinion
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the note opinion.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          create_opinion_note
          notify_admins_and_valuators

          broadcast(:ok, opinion_note)
        end

        private

        attr_reader :form, :opinion_note, :opinion

        def create_opinion_note
          @opinion_note = Decidim.traceability.create!(
            OpinionNote,
            form.current_user,
            {
              body: form.body,
              opinion: opinion,
              author: form.current_user
            },
            resource: {
              title: opinion.title
            }
          )
        end

        def notify_admins_and_valuators
          affected_users = Decidim::User.org_admins_except_me(form.current_user).all
          affected_users += Decidim::Opinions::ValuationAssignment.includes(valuator_role: :user).where.not(id: form.current_user.id).where(opinion: opinion).map(&:valuator)

          data = {
            event: "decidim.events.opinions.admin.opinion_note_created",
            event_class: Decidim::Opinions::Admin::OpinionNoteCreatedEvent,
            resource: opinion,
            affected_users: affected_users
          }

          Decidim::EventsManager.publish(data)
        end
      end
    end
  end
end
