import Component from "@glimmer/component";
import { service } from "@ember/service";
import { subdivisionFlagInfo } from "../lib/subdivision-flags";
import NationalFlag from "./national-flag";
import SubdivisionFlag from "./subdivision-flag";

// Single, consistent flag display used in posts and on the user card/profile.
// Renders the country flag (gated by `location_user_country_flag`) and, where
// available, the region/state flag (gated by `location_user_subdivision_flag`),
// both derived from the user's saved geo_location.
export default class LocationFlags extends Component {
  @service siteSettings;

  get geo() {
    const raw = this.args.geoLocation;
    if (!raw || raw === "{}" || typeof raw !== "object") {
      return null;
    }
    return Object.keys(raw).length ? raw : null;
  }

  get countryCode() {
    if (!this.siteSettings.location_user_country_flag) {
      return null;
    }
    return this.geo?.countrycode || null;
  }

  get subdivision() {
    if (!this.siteSettings.location_user_subdivision_flag || !this.geo) {
      return null;
    }
    return subdivisionFlagInfo(this.geo.countrycode, this.geo.state);
  }

  get hasAnyFlag() {
    return Boolean(this.countryCode || this.subdivision);
  }

  <template>
    {{#if this.hasAnyFlag}}
      <span class="location-flags">
        {{#if this.countryCode}}
          <NationalFlag @countryCode={{this.countryCode}} />
        {{/if}}
        {{#if this.subdivision}}
          <SubdivisionFlag
            @countryCode={{this.geo.countrycode}}
            @state={{this.geo.state}}
          />
        {{/if}}
      </span>
    {{/if}}
  </template>
}
