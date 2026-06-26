# frozen_string_literal: true
module ::Locations
  # Matches users to "regional" groups by proximity. A group is "regional" when
  # it has one or more coverage points stored in its `region_locations` custom
  # field. There are only a handful of these, so matching is plain in-memory
  # distance math (no spatial index needed).
  class RegionGroups
    CUSTOM_FIELD = "region_locations"

    # All groups that have at least one valid coverage point.
    def self.all
      group_ids = GroupCustomField.where(name: CUSTOM_FIELD).pluck(:group_id).uniq
      Group.where(id: group_ids).select { |g| points_for(g).present? }
    end

    def self.region_group?(group)
      points_for(group).present?
    end

    # Parsed, validated coverage points for a group:
    # [{ "lat", "lon", "radius" (km), "label" }, ...]
    def self.points_for(group)
      points = group.region_locations
      return [] unless points.is_a?(Array)

      points.select do |p|
        p.is_a?(Hash) && p["lat"].present? && p["lon"].present?
      end
    end

    # Groups whose coverage contains (lat, lon), nearest first. Each result:
    # { group:, distance_km:, nearest_label: }. Excludes groups in `already_in`.
    def self.near(lat, lon, already_in: [])
      return [] if lat.blank? || lon.blank?

      already = Array(already_in).map(&:to_i)

      all.filter_map do |group|
        next if already.include?(group.id)

        best = nil
        points_for(group).each do |p|
          radius = (p["radius"].presence || SiteSetting.location_region_default_radius).to_f
          distance =
            Locations::Geocode.return_distance(lat.to_f, lon.to_f, p["lat"].to_f, p["lon"].to_f)
          next if distance.nil? || distance > radius

          if best.nil? || distance < best[:distance_km]
            best = { distance_km: distance.round(1), nearest_label: p["label"] }
          end
        end

        { group: group, **best } if best
      end.sort_by { |r| r[:distance_km] }
    end
  end
end
