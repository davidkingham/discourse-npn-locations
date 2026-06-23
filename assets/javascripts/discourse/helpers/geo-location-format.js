import Site from "discourse/models/site";
import { geoLocationFormat } from "../lib/location-utilities";
import trustedHtml from "../lib/trusted-html";

export default function _geoLocationFormat(geoLocation, opts) {
  return trustedHtml(
    geoLocationFormat(geoLocation, Site.currentProp("country_codes"), opts)
  );
}
