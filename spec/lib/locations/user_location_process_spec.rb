# frozen_string_literal: true
require "rails_helper"

RSpec.describe ::Locations::UserLocationProcess do
  fab!(:user)

  def set_geo_location(hash)
    UserCustomField.where(user_id: user.id, name: "geo_location").delete_all
    UserCustomField.create!(user_id: user.id, name: "geo_location", value: hash.to_json)
  end

  describe ".upsert" do
    it "indexes the real coordinates from the stored JSON string" do
      # Regression: geo_location is stored as a raw JSON string (not a :json
      # custom field), so subscripting it directly did substring matching and
      # coerced every user to latitude/longitude 0.0 ("Null Island").
      set_geo_location(lat: 40.7128, lon: -74.006, city: "New York")

      described_class.upsert(user.id)

      loc = ::Locations::UserLocation.find_by(user_id: user.id)
      expect(loc).to be_present
      expect(loc.latitude.to_f).to be_within(0.0001).of(40.7128)
      expect(loc.longitude.to_f).to be_within(0.0001).of(-74.006)
      expect(loc.city).to eq("New York")
    end

    it "does nothing when the stored location has no coordinates" do
      set_geo_location(city: "Nowhere")

      described_class.upsert(user.id)

      expect(::Locations::UserLocation.find_by(user_id: user.id)).to be_nil
    end

    it "does nothing when the location is blank or malformed" do
      UserCustomField.create!(user_id: user.id, name: "geo_location", value: "not json")

      expect { described_class.upsert(user.id) }.not_to raise_error
      expect(::Locations::UserLocation.find_by(user_id: user.id)).to be_nil
    end
  end
end
