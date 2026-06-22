import Component from "@glimmer/component";
import { subdivisionFlagInfo } from "../lib/subdivision-flags";

// Renders a region/state flag derived from geo_location.countrycode + state.
// Resolves to nothing when we don't ship a flag for that subdivision, so it
// never produces a broken image.
export default class SubdivisionFlag extends Component {
  get info() {
    return subdivisionFlagInfo(this.args.countryCode, this.args.state);
  }

  get fileName() {
    const info = this.info;
    if (!info) {
      return null;
    }
    return `/plugins/discourse-npn-locations/images/subdivisionflags/${info.countryCode}/${info.code}.png`;
  }

  <template>
    {{#if this.fileName}}
      <img
        class="subdivision-flag"
        src={{this.fileName}}
        title={{this.info.name}}
        alt={{this.info.name}}
        loading="lazy"
      />
    {{/if}}
  </template>
}
