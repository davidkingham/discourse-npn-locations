import { helperContext } from "discourse/lib/helpers";
import Site from "discourse/models/site";
import { locationFormat } from "../lib/location-utilities";

// Returns a plain string so Glimmer escapes it. The formatter emits only
// comma-joined free text (including the author-typed location name), so marking
// it as trusted HTML would allow stored XSS via that field.
export default function _locationFormat(location, opts) {
  let siteSettings = helperContext().siteSettings;
  return locationFormat(
    location,
    Site.currentProp("country_codes"),
    siteSettings.location_input_fields_enabled,
    siteSettings.location_input_fields,
    siteSettings.location_short_names,
    { ...opts }
  );
}
