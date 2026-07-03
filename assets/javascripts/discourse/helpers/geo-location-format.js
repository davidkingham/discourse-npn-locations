import Site from "discourse/models/site";
import { geoLocationFormat } from "../lib/location-utilities";

// Returns a plain string so Glimmer escapes it. The formatter emits only
// comma-joined free text (city, street, user-typed fields), so marking it as
// trusted HTML would allow stored XSS via those fields.
export default function _geoLocationFormat(geoLocation, opts) {
  return geoLocationFormat(geoLocation, Site.currentProp("country_codes"), opts);
}
