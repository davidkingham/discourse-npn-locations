import Component from "@glimmer/component";

export default class NationalFlagComponent extends Component {
  get code() {
    return this.args.countryCode?.toLowerCase();
  }

  get fileName() {
    return (
      "/plugins/discourse-npn-locations/images/nationalflags/" +
      this.code +
      ".png"
    );
  }

  <template>
    {{#if this.code}}
      <img
        class="national-flag"
        src={{this.fileName}}
        title={{@countryCode}}
        alt={{@countryCode}}
        loading="lazy"
      />
    {{/if}}
  </template>
}
