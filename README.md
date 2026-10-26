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

## Maintenance log

- **2026-10-26 — `v7.2.0-npn.4`:** The CI image moved to Ruby 4.0, where `benchmark` is no
  longer a default gem, so the old rubocop 1.50.2 crashed the linting job. Bumped
  rubocop-discourse to 3.20.0 (rubocop 1.92.1) and fixed the new style offenses. Four plugin
  cops are disabled in `.rubocop.yml` because satisfying them changes runtime behavior
  (`requires_plugin` on the geocode controller, plugin-scoped `on` for the three
  `DiscourseEvent.on` handlers, `require_relative` in `plugin.rb`, and replacing the
  `::TopicQuery` reopen with a prepended mixin). Do them as a separate change and re-enable the
  cops. Also gave `claude-fix.yml` the `id-token: write` and `actions: read` permissions it was
  missing.
- **2026-08-10 — `v7.2.0-npn.3`:** Resolved the `discourse.modify-class-model` deprecation
  (core 2026.8) by replacing `api.modifyClass` on `model:composer` and `model:topic` with the
  model extension APIs (`addModelField` / `addModelGetter` / `addModelMethod`). The composer's
  default-location lifecycle moved into the `composer-controls-location` connector
  (`didInsert`/`didUpdate`). Ported from upstream
  [merefield/discourse-locations#169](https://github.com/merefield/discourse-locations/pull/169).
  `main` now requires core ≥ 2026.7.0; older cores are pinned to the pre-migration commit via
  `.discourse-compatibility`.

## Lineage

Forked from discourse-locations (GPL-2.0) by Robert Barrow & Angus McLeod / Pavilion. License
unchanged; see `LICENSE.txt` and `COPYRIGHT.txt`. Fork is based on upstream `v7.2.0`; upstream
changes are ported selectively (see the maintenance log).
