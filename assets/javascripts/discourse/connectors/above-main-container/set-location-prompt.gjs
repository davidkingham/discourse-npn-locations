import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";
import LocationSelector from "../../components/location-selector";

const DISMISS_KEY = "npn-location-prompt-dismissed";
// UI-only keys the selector attaches to results; not part of the stored location.
const NON_GEO_KEYS = ["id", "geoAttrs", "showType", "provider"];

// Site-wide banner prompting logged-in users with no saved location to add one,
// so the users map stays current. Lets them set it inline via the geocoded
// LocationSelector, or fall back to a setup page link.
export default class SetLocationPrompt extends Component {
  @service currentUser;
  @service siteSettings;

  @tracked selectedGeo = null;
  @tracked saving = false;
  @tracked error = null;
  @tracked dismissed = this.readDismissed();

  readDismissed() {
    try {
      return window.sessionStorage?.getItem(DISMISS_KEY) === "1";
    } catch {
      return false;
    }
  }

  get hasLocation() {
    const geo = this.currentUser?.geo_location;
    return Boolean(geo && typeof geo === "object" && Object.keys(geo).length);
  }

  get shouldShow() {
    return (
      this.siteSettings.location_prompt_enabled &&
      this.currentUser &&
      !this.hasLocation &&
      !this.dismissed
    );
  }

  get canSave() {
    return Boolean(
      this.selectedGeo?.lat && this.selectedGeo?.lon && !this.saving
    );
  }

  get disabled() {
    return !this.canSave;
  }

  get setupUrl() {
    return this.siteSettings.location_prompt_setup_url;
  }

  @action
  onSelect(location) {
    this.error = null;
    this.selectedGeo = location || null;
  }

  @action
  async save() {
    if (!this.canSave) {
      return;
    }
    this.saving = true;
    this.error = null;

    const clean = { ...this.selectedGeo };
    NON_GEO_KEYS.forEach((k) => delete clean[k]);

    try {
      await ajax(`/u/${this.currentUser.username}.json`, {
        type: "PUT",
        data: { custom_fields: { geo_location: JSON.stringify(clean) } },
      });
      // Flips hasLocation -> banner hides; also drives flags immediately.
      this.currentUser.set("geo_location", clean);
    } catch {
      this.error = i18n("location.set_location_prompt.error");
    } finally {
      this.saving = false;
    }
  }

  @action
  dismiss() {
    try {
      window.sessionStorage?.setItem(DISMISS_KEY, "1");
    } catch {
      // sessionStorage unavailable (e.g. private mode); dismiss for this view only
    }
    this.dismissed = true;
  }

  <template>
    {{#if this.shouldShow}}
      <div class="set-location-prompt alert">
        <div class="set-location-prompt__body">
          <span class="set-location-prompt__message">
            {{i18n "location.set_location_prompt.message"}}
          </span>
          <div class="set-location-prompt__controls">
            <LocationSelector
              @location={{this.selectedGeo}}
              @onChangeCallback={{this.onSelect}}
              @showType={{false}}
              @placeholder={{i18n "location.set_location_prompt.placeholder"}}
              class="set-location-prompt__selector"
            />
            <button
              type="button"
              class="btn btn-primary set-location-prompt__save"
              disabled={{this.disabled}}
              {{on "click" this.save}}
            >
              {{if
                this.saving
                (i18n "location.set_location_prompt.saving")
                (i18n "location.set_location_prompt.save")
              }}
            </button>
            <button
              type="button"
              class="btn btn-flat set-location-prompt__dismiss"
              {{on "click" this.dismiss}}
            >
              {{i18n "location.set_location_prompt.dismiss"}}
            </button>
          </div>
        </div>

        {{#if this.error}}
          <div class="set-location-prompt__error">{{this.error}}</div>
        {{/if}}

        {{#if this.setupUrl}}
          <a class="set-location-prompt__setup-link" href={{this.setupUrl}}>
            {{i18n "location.set_location_prompt.setup_link"}}
          </a>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
