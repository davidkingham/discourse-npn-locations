# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Post user_custom_fields geo_location serialization" do
  fab!(:author) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic, user: author) }
  fab!(:post) { Fabricate(:post, topic: topic, user: author) }

  before do
    SiteSetting.location_enabled = true
    SiteSetting.location_users_map = true
    UserCustomField.create!(
      user_id: author.id,
      name: "geo_location",
      value: { lat: 51.5, lon: -0.12, city: "London" }.to_json,
    )
  end

  it "serializes the author's geo_location as a parsed hash via the preloaded path" do
    get "/t/#{topic.id}.json"
    expect(response.status).to eq(200)

    post_json = response.parsed_body["post_stream"]["posts"].find { |p| p["id"] == post.id }
    geo = post_json.dig("user_custom_fields", "geo_location")
    expect(geo).to be_a(Hash)
    expect(geo["lat"].to_f).to be_within(0.0001).of(51.5)
    expect(geo["city"]).to eq("London")
  end
end
