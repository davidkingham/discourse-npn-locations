import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

const DISMISS_KEY = "npn-region-suggestion-dismissed";

// After a member has a saved location, suggest the regional chapter(s) whose
// coverage contains them, with one-click join. Sibling to set-location-prompt.
export default class RegionSuggestions extends Component {
  @service currentUser;
  @service siteSettings;

  @tracked suggestions = [];
  @tracked loaded = false;
  @tracked dismissed = this.readDismissed();
  @tracked joiningId = null;

  constructor() {
    super(...arguments);
    this.load();
  }

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

  get eligible() {
    return (
      this.siteSettings.location_region_groups_enabled &&
      this.siteSettings.location_region_suggestion_enabled &&
      this.currentUser &&
      this.hasLocation &&
      !this.currentUser.dismissed_region_suggestion &&
      !this.dismissed
    );
  }

  get shouldShow() {
    return this.eligible && this.loaded && this.suggestions.length > 0;
  }

  @action
  async load() {
    if (!this.eligible) {
      return;
    }
    try {
      const result = await ajax("/locations/regions/near");
      this.suggestions = result.regions || [];
    } catch {
      // discovery is best-effort; stay silent on failure
    } finally {
      this.loaded = true;
    }
  }

  @action
  async join(region) {
    this.joiningId = region.group.id;
    try {
      await ajax(`/locations/regions/${region.group.id}/join`, {
        type: "POST",
      });
      this.suggestions = this.suggestions.filter(
        (r) => r.group.id !== region.group.id
      );
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.joiningId = null;
    }
  }

  @action
  dismiss() {
    try {
      window.sessionStorage?.setItem(DISMISS_KEY, "1");
    } catch {
      // sessionStorage unavailable; dismiss for this view only
    }
    this.dismissed = true;
  }

  @action
  async dontShowAgain() {
    try {
      await ajax(`/u/${this.currentUser.username}.json`, {
        type: "PUT",
        data: { custom_fields: { dismissed_region_suggestion: true } },
      });
      this.currentUser.set("dismissed_region_suggestion", true);
    } catch (e) {
      popupAjaxError(e);
    }
  }

  <template>
    {{#if this.shouldShow}}
      <div class="region-suggestions alert">
        <div class="region-suggestions__text">
          <h2 class="region-suggestions__title">
            {{icon "user-group"}}
            {{i18n "location.region_suggestion.title"}}
          </h2>
          <p class="region-suggestions__message">
            {{i18n "location.region_suggestion.message"}}
          </p>
        </div>

        <div class="region-suggestions__list">
          {{#each this.suggestions as |region|}}
            <div class="region-suggestions__card">
              <div class="region-suggestions__info">
                <span class="region-suggestions__name">
                  {{if
                    region.group.full_name
                    region.group.full_name
                    region.group.name
                  }}
                </span>
                <span class="region-suggestions__meta">
                  {{region.nearest_label}}
                  ·
                  {{i18n
                    "location.region_suggestion.distance"
                    km=region.distance_km
                  }}
                </span>
              </div>
              <DButton
                @label="location.region_suggestion.join"
                @action={{fn this.join region}}
                @disabled={{eq this.joiningId region.group.id}}
                class="btn-primary region-suggestions__join"
              />
            </div>
          {{/each}}
        </div>

        <div class="region-suggestions__dismiss-row">
          <button
            type="button"
            class="btn btn-flat region-suggestions__dismiss"
            {{on "click" this.dismiss}}
          >
            {{i18n "location.region_suggestion.dismiss"}}
          </button>
          <span
            class="region-suggestions__dismiss-sep"
            aria-hidden="true"
          >·</span>
          <button
            type="button"
            class="btn btn-flat region-suggestions__opt-out"
            {{on "click" this.dontShowAgain}}
          >
            {{i18n "location.region_suggestion.dont_show"}}
          </button>
        </div>
      </div>
    {{/if}}
  </template>
}
