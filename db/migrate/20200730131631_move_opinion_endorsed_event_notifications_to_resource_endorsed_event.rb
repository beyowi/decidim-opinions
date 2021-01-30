# frozen_string_literal: true

class MoveOpinionEndorsedEventNotificationsToResourceEndorsedEvent < ActiveRecord::Migration[5.2]
  def up
    Decidim::Notification.where(event_name: "decidim.events.opinions.opinion_endorsed", event_class: "Decidim::Opinions::OpinionEndorsedEvent").find_each do |notification|
      notification.update(event_name: "decidim.events.resource_endorsed", event_class: "Decidim::ResourceEndorsedEvent")
    end
  end

  def down
    Decidim::Notification.where(
      event_name: "decidim.events.resource_endorsed",
      event_class: "Decidim::ResourceEndorsedEvent",
      decidim_resource_type: "Decidim::Opinions::Opinion"
    )
                         .find_each do |notification|
      notification.update(event_name: "decidim.events.opinions.opinion_endorsed", event_class: "Decidim::Opinions::OpinionEndorsedEvent")
    end
  end
end
