import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
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

  get optedOut() {
    return Boolean(this.currentUser?.dismissed_location_prompt);
  }

  get shouldShow() {
    return (
      this.siteSettings.location_prompt_enabled &&
      this.currentUser &&
      !this.hasLocation &&
      !this.optedOut &&
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

  @action
  onSelect(location) {
    this.error = null;
    this.selectedGeo = location || null;
  }

  async updateCustomFields(fields) {
    await ajax(`/u/${this.currentUser.username}.json`, {
      type: "PUT",
      data: { custom_fields: fields },
    });
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
      await this.updateCustomFields({ geo_location: JSON.stringify(clean) });
      // Flips hasLocation -> banner hides; also drives flags immediately.
      this.currentUser.set("geo_location", clean);
    } catch {
      this.error = i18n("location.set_location_prompt.error");
    } finally {
      this.saving = false;
    }
  }

  @action
  async dontRemind() {
    this.saving = true;
    this.error = null;

    try {
      await this.updateCustomFields({ dismissed_location_prompt: true });
      // Persists across sessions/devices -> banner stays hidden.
      this.currentUser.set("dismissed_location_prompt", true);
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
        <div class="set-location-prompt__text">
          <h2 class="set-location-prompt__title">
            {{icon "location-dot"}}
            {{i18n "location.set_location_prompt.title"}}
          </h2>
          <p class="set-location-prompt__message">
            {{i18n "location.set_location_prompt.message"}}
          </p>
        </div>

        <div class="set-location-prompt__form">
          <div class="set-location-prompt__field-row">
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
          </div>
          <span class="set-location-prompt__helper">
            {{i18n "location.set_location_prompt.helper"}}
          </span>
        </div>

        {{#if this.error}}
          <div class="set-location-prompt__error">{{this.error}}</div>
        {{/if}}

        <div class="set-location-prompt__dismiss-row">
          <button
            type="button"
            class="btn btn-flat set-location-prompt__dismiss"
            {{on "click" this.dismiss}}
          >
            {{i18n "location.set_location_prompt.dismiss"}}
          </button>
          <span class="set-location-prompt__dismiss-sep" aria-hidden="true">·</span>
          <button
            type="button"
            class="btn btn-flat set-location-prompt__opt-out"
            disabled={{this.saving}}
            {{on "click" this.dontRemind}}
          >
            {{i18n "location.set_location_prompt.dont_remind"}}
          </button>
        </div>
      </div>
    {{/if}}
  </template>
}
