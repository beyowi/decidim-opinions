# frozen_string_literal: true

module Decidim
  module Opinions
    # This helper include some methods for rendering opinions dynamic maps.
    module MapHelper
      include Decidim::ApplicationHelper
      # Serialize a collection of geocoded opinions to be used by the dynamic map component
      #
      # geocoded_opinions - A collection of geocoded opinions
      def opinions_data_for_map(geocoded_opinions)
        geocoded_opinions.map do |opinion|
          opinion.slice(:latitude, :longitude, :address).merge(title: present(opinion).title,
                                                                body: truncate(present(opinion).body, length: 100),
                                                                icon: icon("opinions", width: 40, height: 70, remove_icon_class: true),
                                                                link: opinion_path(opinion))
        end
      end
    end
  end
end
