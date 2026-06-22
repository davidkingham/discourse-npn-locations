import Component from "@glimmer/component";
import { service } from "@ember/service";
import LocationFlags from "../../components/location-flags";
import { geoLocationFormat } from "../../lib/location-utilities";

export default class LocationMapComponent extends Component {
  @service siteSettings;
  @service site;

  get geoLocation() {
    let model = this.args.post;

    if (model.user_custom_fields && model.user_custom_fields["geo_location"]) {
      return model.user_custom_fields["geo_location"];
    }
    return null;
  }

  get locationText() {
    if (this.geoLocation) {
      let format = this.siteSettings.location_user_post_format.split("|");
      let opts = {};

      if (format.length) {
        opts["geoAttrs"] = format;
      }

      return geoLocationFormat(this.geoLocation, this.site.country_codes, opts);
    }
    return "";
  }

  <template>
    {{yield}}
    <div class="location-summary">
      <div class="user-location">{{this.locationText}}</div>
      <LocationFlags @geoLocation={{this.geoLocation}} />
    </div>
  </template>
}
