# frozen_string_literal: true

module Decidim
  module Plans
    module PlansHelper
      def has_geocoding?
        address_section.present?
      end

      # Serialize a collection of geocoded ideas to be used by the dynamic map
      # component. The serialized list is made for the flat list fetched with
      # `Plan.geocoded_data_for` in order to make the processing faster.
      #
      # geocoded_plans_data - A flat array of the plan data received from `Plan.geocoded_data_for`
      def plans_data_for_map(geocoded_plans_data)
        geocoded_plans_data.map do |data|
          tmp = {
            id: data[:id],
            title: translated_attribute(data[:title]),
            body: truncate(translated_attribute(data[:body]), length: 100),
            address: data[:address],
            latitude: data[:latitude],
            longitude: data[:longitude],
            link: plan_path(data[:id])
          }
        end
      end

      def plans_map(geocoded_plans)
        map_options = { type: "plans", markers: geocoded_plans }

        if address_section
          lat = address_section.settings["map_center_latitude"]
          lng = address_section.settings["map_center_longitude"]

          map_options[:center_coordinates] = [lat, lng].map(&:to_f) if lat && lng
        end

        dynamic_map_for(map_options) do
          yield
        end
      end

      # Retrieves the first address section which is used for some settings.
      def address_section
        @address_section ||= Decidim::Plans::Section.order(:position).find_by(
          component: current_component,
          section_type: "field_map_point"
        )
      end
    end
  end
end