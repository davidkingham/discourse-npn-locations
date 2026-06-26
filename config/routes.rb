# frozen_string_literal: true
Locations::Engine.routes.draw do
  get 'search' => 'geocode#search'
  get 'validate' => 'geocode#validate'
  get 'countries' => 'geocode#countries'
  get "users_map" => "users_map#index"

  # Regional groups: discovery + join, and the regions map data.
  get "regions" => "regions#index"
  get "regions/near" => "regions#near"
  post "regions/:group_id/join" => "regions#join"

  # Admin: manage each group's coverage points.
  get "admin/region-groups" => "admin/region_groups#index"
  put "admin/region-groups/:group_id" => "admin/region_groups#update"
end

Discourse::Application.routes.draw do
  get 'map_feed' => 'list#map_feed'
  mount ::Locations::Engine, at: 'locations'
end
