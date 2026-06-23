# frozen_string_literal: true

module PageObjects
  module Components
    class LocationSelector < PageObjects::Components::Base
      def initialize(context)
        @context = context
      end

      def hidden?
        page.has_no_css?("#{@context} .location-selector-inline__field")
      end

      def has_selected_location_with_string?(string)
        find(@context).has_field?(
          class: "location-selector-inline__input",
          with: string
        )
      end

      def has_no_selected_locations?
        # The clear button only renders while the field has a value, so its
        # absence means there is no selected location.
        find(@context).has_no_css?(".location-selector-inline__clear")
      end

      def open
        find("#{@context} .location-selector-inline__input").click
      end

      def add_location(location_name)
        find("#{@context} .location-selector-inline__input").set(location_name)
        find(
          "#{@context} .location-selector-inline__result",
          match: :first
        ).click
      end

      def remove_location(_location_name = nil)
        find("#{@context} .location-selector-inline__clear").click
      end
    end
  end
end
