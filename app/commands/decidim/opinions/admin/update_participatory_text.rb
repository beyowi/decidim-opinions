# frozen_string_literal: true

module Decidim
  module Opinions
    module Admin
      # A command with all the business logic when an admin updates participatory text opinions.
      class UpdateParticipatoryText < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A PreviewParticipatoryTextForm form object with the params.
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          transaction do
            @failures = {}
            update_contents_and_resort_opinions(form)
          end

          if @failures.any?
            broadcast(:invalid, @failures)
          else
            broadcast(:ok)
          end
        end

        private

        attr_reader :form

        # Prevents PaperTrail from creating versions while updating participatory text opinions.
        # A first version will be created when publishing the Participatory Text.
        def update_contents_and_resort_opinions(form)
          PaperTrail.request(enabled: false) do
            form.opinions.each do |prop_form|
              opinion = Opinion.where(component: form.current_component).find(prop_form.id)
              opinion.set_list_position(prop_form.position) if opinion.position != prop_form.position
              opinion.title = prop_form.title
              opinion.body = prop_form.body if opinion.participatory_text_level == ParticipatoryTextSection::LEVELS[:article]

              add_failure(opinion) unless opinion.save
            end
          end
          raise ActiveRecord::Rollback if @failures.any?
        end

        def add_failure(opinion)
          @failures[opinion.id] = opinion.errors.full_messages
        end
      end
    end
  end
end
