# frozen_string_literal: true

module ::Locations
  class UserLocationProcess

    def self.upsert(user_id)
      user = User.find_by(id: user_id)
      return if user.nil?

      # `geo_location` is not registered as a :json custom field, so the stored
      # value is a raw JSON string. Parse it to a Hash before indexing —
      # subscripting the raw string (`str['lat']`) does substring matching and
      # silently coerces to 0.0, placing every user on Null Island.
      geo = ::Locations.parse_geo_location(user.custom_fields['geo_location'])
      return unless geo.is_a?(Hash) && geo['lat'].present? && geo['lon'].present?

      ::Locations::UserLocation.upsert({
          user_id: user_id,
          latitude: geo['lat'],
          longitude: geo['lon'],
          street: geo['street'] || nil,
          district: geo['district'] || nil,
          city: geo['city'] || nil,
          state: geo['state'] || nil,
          postalcode: geo['postalcode'] || nil,
          country: geo['country'] || nil,
          countrycode: geo['countrycode'] || nil,
          international_code: geo['international_code'] || nil,
          locationtype: geo['type'] || nil,
          boundingbox: geo['boundingbox'] || nil,
        },
        on_duplicate: :update, unique_by: :user_id
      )
    end

    def self.delete(user_id)
      location = ::Locations::UserLocation.find_by(user_id: user_id)
      location.delete if location
    end

    def self.search_users_from_user_location(user_id, distance)
      user_location = UserLocation.find_by(user_id: user_id)

      return [] if !user_location || !user_location.geocoded?

      user_location.nearbys(distance, units: :km, select_distance: false, select_bearing: false).joins(:user).pluck(:user_id)
    end

    def self.search_users_from_location(lat, lon, distance)

      return [] if lat.nil? || lon.nil?

      UserLocation.near([lat.to_f, lon.to_f], distance.to_f, units: :km, select_distance: false, select_bearing: false).joins(:user).pluck(:user_id)
    end

    def self.get_user_distance_from_location(user_id, lat, lon)
      user_location = UserLocation.find_by(user_id: user_id)

      return nil if !user_location || !user_location.geocoded?

      user_location.distance_to([lat, lon], :km)
    end

    def self.search_topics_from_user_location(user_id, distance)
      user_location = UserLocation.find_by(user_id: user_id)

      return [] if !user_location || !user_location.geocoded?

      TopicLocation.near([user_location.latitude, user_location.longitude], distance, units: :km, select_distance: false, select_bearing: false).joins(:topic).pluck(:topic_id)
    end

    def self.search_users_from_topic_location(topic_id, distance)
      topic_location = TopicLocation.find_by(user_id: topic_id)

      return [] if !topic_location || !topic_location.geocoded?

      UserLocation.near([topic_location.latitude, topic_location.longitude], distance, units: :km, select_distance: false, select_bearing: false).joins(:user).pluck(:user_id)
    end
  end
end
