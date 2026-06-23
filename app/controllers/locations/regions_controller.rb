# frozen_string_literal: true
module ::Locations
  class RegionsController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    before_action :ensure_logged_in
    before_action :ensure_region_groups_enabled

    # All regional groups + their coverage points, for the regions map.
    def index
      regions =
        Locations::RegionGroups.all.map do |group|
          {
            group: serialize_data(group, BasicGroupSerializer),
            points: Locations::RegionGroups.points_for(group)
          }
        end
      render json: { regions: regions }
    end

    # Regional groups whose coverage contains the current user's saved location,
    # nearest first, excluding groups they already belong to.
    def near
      render json: { regions: serialize_near(matches_for_current_user) }
    end

    # Join a regional group the user is actually near (re-validated server-side).
    def join
      unless current_user.staff?
        RateLimiter.new(current_user, "region_group_join", 10, 1.minute).performed!
      end

      group = Group.find_by(id: params[:group_id])
      raise Discourse::NotFound unless group && Locations::RegionGroups.region_group?(group)

      geo = current_user_geo
      within =
        geo.present? &&
          Locations::RegionGroups.near(geo["lat"], geo["lon"]).any? { |m| m[:group].id == group.id }
      raise Discourse::InvalidAccess.new("not within region") unless within

      unless group.users.exists?(id: current_user.id)
        group.add(current_user)
        GroupActionLogger.new(current_user, group).log_add_user_to_group(current_user)
      end

      render json: success_json
    end

    private

    def ensure_region_groups_enabled
      raise Discourse::NotFound unless SiteSetting.location_region_groups_enabled
    end

    def current_user_geo
      geo = Locations.parse_geo_location(current_user.custom_fields["geo_location"])
      return nil if geo.blank? || geo["lat"].blank? || geo["lon"].blank?
      geo
    end

    def matches_for_current_user
      geo = current_user_geo
      return [] if geo.blank?
      Locations::RegionGroups.near(geo["lat"], geo["lon"], already_in: current_user.group_ids)
    end

    def serialize_near(matches)
      matches.map do |m|
        {
          group: serialize_data(m[:group], BasicGroupSerializer),
          distance_km: m[:distance_km],
          nearest_label: m[:nearest_label]
        }
      end
    end
  end
end
