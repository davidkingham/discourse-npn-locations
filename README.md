# Discourse NPN Locations Plugin

A private fork of [merefield/discourse-locations](https://github.com/merefield/discourse-locations)
maintained for use on a single site. It keeps the upstream feature set — geocoded locations on
topics, a topic/category location map, and voluntary user locations shown on a map in the user
directory — and layers on site-specific additions.

> **Data compatibility:** this fork reads and writes the same Discourse custom-field keys as
> upstream (`user_custom_fields['geo_location']`, `topic_custom_fields['location']`, etc.) and keeps
> the same `location_*` site-setting names. Existing location data and admin configuration carry over
> with no migration.

## Additions over upstream

- **Location-derived flags.** Country flags already render from `geo_location.countrycode` upstream
  (enable `location_user_country_flag`). This fork extends that with **subdivision flags** (US state
  flags now, extensible to other countries) derived from `geo_location.state`, plus a cleaner flag
  display. This replaces the standalone
  [discourse-nationalflags](https://github.com/chapoi/discourse-nationalflags) plugin.

## Lineage

Forked from discourse-locations (GPL-2.0) by Robert Barrow & Angus McLeod / Pavilion. License
unchanged; see `LICENSE.txt` and `COPYRIGHT.txt`.
