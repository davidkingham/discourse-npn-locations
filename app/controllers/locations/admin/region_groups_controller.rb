# frozen_string_literal: true
module ::Locations
  module Admin
    # Staff-only management of each group's coverage points (center + radius).
    class RegionGroupsController < ::Admin::AdminController
      requires_plugin PLUGIN_NAME

      def index
        render json: { region_groups: Locations::RegionGroups.all.map { |g| present(g) } }
      end

      def update
        group = Group.find(params[:group_id])
        points = sanitize_points(params.permit(points: %i[lat lon radius label])[:points])
        group.custom_fields["region_locations"] = points
        group.save_custom_fields(true)
        render json: present(group)
      end

      private

      def present(group)
        {
          id: group.id,
          name: group.name,
          full_name: group.full_name,
          points: Locations::RegionGroups.points_for(group)
        }
      end

      def sanitize_points(list)
        Array(list).filter_map do |p|
          next if p[:lat].blank? || p[:lon].blank?
          {
            "lat" => p[:lat].to_f,
            "lon" => p[:lon].to_f,
            "radius" => (p[:radius].presence || SiteSetting.location_region_default_radius).to_f,
            "label" => p[:label].to_s
          }
        end
      end
    end
  end
end
