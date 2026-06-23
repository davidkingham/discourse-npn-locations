# frozen_string_literal: true
require "rails_helper"

describe "Regional groups", type: :request do
  fab!(:user)
  fab!(:admin)
  fab!(:region_group) { Fabricate(:group, name: "denver-chapter", full_name: "Denver Chapter") }
  fab!(:far_group) { Fabricate(:group, name: "tokyo-chapter") }

  before do
    SiteSetting.location_enabled = true
    SiteSetting.location_region_groups_enabled = true

    region_group.custom_fields["region_locations"] = [
      { "lat" => 39.7392, "lon" => -104.9903, "radius" => 100, "label" => "Denver" },
    ]
    region_group.save_custom_fields(true)

    far_group.custom_fields["region_locations"] = [
      { "lat" => 35.6762, "lon" => 139.6503, "radius" => 100, "label" => "Tokyo" },
    ]
    far_group.save_custom_fields(true)

    UserCustomField.create!(
      user_id: user.id,
      name: "geo_location",
      value: { lat: 39.75, lon: -104.99, city: "Denver", countrycode: "us" }.to_json,
    )
  end

  describe "GET /locations/regions/near" do
    it "returns regional groups within radius and excludes far ones" do
      sign_in(user)
      get "/locations/regions/near.json"
      expect(response.status).to eq(200)
      names = response.parsed_body["regions"].map { |r| r["group"]["name"] }
      expect(names).to include("denver-chapter")
      expect(names).not_to include("tokyo-chapter")
    end

    it "excludes groups the user already belongs to" do
      region_group.add(user)
      sign_in(user)
      get "/locations/regions/near.json"
      names = response.parsed_body["regions"].map { |r| r["group"]["name"] }
      expect(names).not_to include("denver-chapter")
    end

    it "404s when the feature is disabled" do
      SiteSetting.location_region_groups_enabled = false
      sign_in(user)
      get "/locations/regions/near.json"
      expect(response.status).to eq(404)
    end
  end

  describe "POST /locations/regions/:group_id/join" do
    it "adds the user when within range" do
      sign_in(user)
      post "/locations/regions/#{region_group.id}/join.json"
      expect(response.status).to eq(200)
      expect(region_group.reload.users).to include(user)
    end

    it "refuses to join a region the user isn't near" do
      sign_in(user)
      post "/locations/regions/#{far_group.id}/join.json"
      expect(response.status).to eq(403)
      expect(far_group.reload.users).not_to include(user)
    end
  end

  describe "admin PUT /locations/admin/region-groups/:group_id" do
    it "saves coverage points for the group" do
      sign_in(admin)
      put "/locations/admin/region-groups/#{region_group.id}.json",
          params: {
            points: [{ lat: 40.015, lon: -105.27, radius: 50, label: "Boulder" }],
          }
      expect(response.status).to eq(200)
      points = region_group.reload.region_locations
      expect(points.size).to eq(1)
      expect(points.first["label"]).to eq("Boulder")
      expect(points.first["radius"]).to eq(50.0)
    end

    it "is staff-only" do
      sign_in(user)
      put "/locations/admin/region-groups/#{region_group.id}.json", params: { points: [] }
      expect(response.status).to eq(404)
    end
  end
end
