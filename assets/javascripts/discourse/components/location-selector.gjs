import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import {
  geoLocationFormat,
  geoLocationSearch,
  providerDetails,
} from "../lib/location-utilities";
import trustedHtml from "../lib/trusted-html";

/**
 * Inline geocoded location search input.
 *
 * Type directly in the field; matching addresses appear in a dropdown beneath
 * it. Selecting one calls @onChangeCallback with the full location object.
 *
 * @param {Object}   @location - Pre-selected location object (uses .address)
 * @param {string}   @context - Optional context passed to the geocoder
 * @param {Array}    @geoAttrs - Attributes used to format the display text
 * @param {boolean}  @showType - Reserved (kept for API compatibility)
 * @param {string}   @placeholder - Input placeholder
 * @param {function} @onChangeCallback - Called with the selected location (or {} when cleared)
 * @param {function} @searchError - Called with an error message on search failure
 * @param {boolean}  @coarse - Privacy mode for user/community-map locations:
 *   "use current location" resolves to the town (not exact GPS), and every
 *   selection is scattered to a random point within its bounding box so pins
 *   stay approximate and don't stack. Leave off for precise (e.g. topic) use.
 */
export default class LocationSelector extends Component {
  @service siteSettings;
  @service site;

  @tracked searchTerm = "";
  @tracked results = [];
  @tracked loading = false;
  @tracked isOpen = false;
  @tracked activeIndex = -1;
  @tracked provider = null;
  @tracked searched = false;

  element = null;
  _outsideHandler = null;

  constructor() {
    super(...arguments);
    if (this.args.location?.address) {
      this.searchTerm = this.displayText(this.args.location);
    }
  }

  @action
  displayText(location) {
    if (location && typeof location === "object" && location.address) {
      return geoLocationFormat(location, this.site.country_codes, {
        geoAttrs: this.args.geoAttrs,
      });
    }
    return location?.address ?? "";
  }

  get showResults() {
    return (
      this.isOpen && (this.loading || this.results.length || this.searched)
    );
  }

  get providerLabel() {
    return this.provider ? providerDetails[this.provider] : null;
  }

  @action
  setup(element) {
    this.element = element;
    this._outsideHandler = (e) => {
      if (this.element && !this.element.contains(e.target)) {
        this.isOpen = false;
      }
    };
    document.addEventListener("click", this._outsideHandler, true);
  }

  @action
  teardown() {
    if (this._outsideHandler) {
      document.removeEventListener("click", this._outsideHandler, true);
      this._outsideHandler = null;
    }
  }

  @action
  onFocus() {
    if (this.results.length || this.searched) {
      this.isOpen = true;
    }
  }

  @action
  onInput(event) {
    this.searchTerm = event.target.value;
    this.activeIndex = -1;

    const term = this.searchTerm.trim();
    if (!term) {
      this.results = [];
      this.searched = false;
      this.isOpen = false;
      this.loading = false;
      this.args.onChangeCallback?.({});
      return;
    }

    this.isOpen = true;
    this.search(term);
  }

  async search(term) {
    this.loading = true;
    const request = { query: term };
    if (this.args.context) {
      request.context = this.args.context;
    }

    try {
      const r = await geoLocationSearch(
        request,
        this.siteSettings.location_geocoding_debounce
      );

      // Ignore stale responses (the user kept typing).
      if (term !== this.searchTerm.trim()) {
        return;
      }

      this.results = (r?.locations || []).filter((l) => l && !l.provider);
      this.provider =
        r?.provider || this.siteSettings.location_geocoding_provider;
      this.searched = true;
      this.loading = false;
    } catch (e) {
      this.loading = false;
      this.results = [];
      this.searched = true;
      this.args.searchError?.(e);
    }
  }

  // Geocode a query and return the first real (non-attribution) result.
  async geocodeFirst(query) {
    const r = await geoLocationSearch(
      { query },
      this.siteSettings.location_geocoding_debounce
    );
    return (r?.locations || []).find((l) => l && !l.provider) || null;
  }

  // Move a location to a random point within its bounding box, so many users in
  // the same town spread across the area instead of stacking on one pin. The
  // address/town stays the same; only the coordinates are scattered. Falls back
  // to the original point if there's no usable bounding box. Bounding box order
  // (Nominatim): [minLat, maxLat, minLon, maxLon].
  scatterWithinArea(location) {
    const bb = location?.boundingbox;
    if (!Array.isArray(bb) || bb.length < 4) {
      return location;
    }
    const [minLat, maxLat, minLon, maxLon] = bb.map(parseFloat);
    if ([minLat, maxLat, minLon, maxLon].some((n) => Number.isNaN(n))) {
      return location;
    }
    return {
      ...location,
      lat: minLat + Math.random() * (maxLat - minLat),
      lon: minLon + Math.random() * (maxLon - minLon),
    };
  }

  @action
  select(location) {
    // In coarse mode (user/community-map locations) scatter to a random nearby
    // point so the stored location stays approximate and pins don't stack.
    const final = this.args.coarse
      ? this.scatterWithinArea(location)
      : location;
    this.args.onChangeCallback?.(final);
    this.searchTerm = this.displayText(final);
    this.results = [];
    this.searched = false;
    this.activeIndex = -1;
    this.isOpen = false;
  }

  @action
  clear() {
    this.searchTerm = "";
    this.results = [];
    this.searched = false;
    this.activeIndex = -1;
    this.isOpen = false;
    this.args.onChangeCallback?.({});
  }

  @action
  setActive(index) {
    this.activeIndex = index;
  }

  @action
  onKeydown(event) {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      if (!this.results.length) {
        return;
      }
      this.isOpen = true;
      this.activeIndex = Math.min(
        this.activeIndex + 1,
        this.results.length - 1
      );
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      this.activeIndex = Math.max(this.activeIndex - 1, 0);
    } else if (event.key === "Enter") {
      if (this.isOpen && this.results[this.activeIndex]) {
        event.preventDefault();
        this.select(this.results[this.activeIndex]);
      }
    } else if (event.key === "Escape") {
      this.isOpen = false;
    }
  }

  @action
  async useCurrentLocation() {
    if (!navigator.geolocation) {
      return;
    }

    this.loading = true;
    this.isOpen = false;

    let coords;
    try {
      coords = await new Promise((resolve, reject) =>
        navigator.geolocation.getCurrentPosition(
          (pos) => resolve(pos.coords),
          reject
        )
      );
    } catch {
      // Permission denied or unavailable.
      this.loading = false;
      return;
    }

    try {
      // 1. Reverse-geocode the precise coords just to learn the town/region.
      const place = await this.geocodeFirst(
        `${coords.latitude}, ${coords.longitude}`
      );
      if (!place) {
        return;
      }

      // 2. Re-geocode the town name so we store a generic, town-level location
      //    (the town's centroid) instead of the user's exact GPS position.
      // Exact mode (e.g. topic locations): use the precise position.
      if (!this.args.coarse) {
        this.select(place);
        return;
      }

      // Coarse mode: re-geocode the town for a generic location; select() then
      // scatters it within the town so users don't share a pin.
      const parts = [
        place.city || place.district,
        place.state,
        place.country,
      ].filter(Boolean);

      const generic = parts.length
        ? await this.geocodeFirst(parts.join(", "))
        : null;

      this.select(generic || place);
    } catch (e) {
      this.args.searchError?.(e);
    } finally {
      this.loading = false;
    }
  }

  <template>
    <div
      class="location-selector-wrapper location-selector-inline"
      {{didInsert this.setup}}
      {{willDestroy this.teardown}}
      ...attributes
    >
      <div class="location-selector-inline__field">
        {{icon
          "magnifying-glass"
          class="location-selector-inline__search-icon"
        }}
        <input
          type="text"
          class="location-selector-inline__input"
          placeholder={{@placeholder}}
          value={{this.searchTerm}}
          autocomplete="off"
          spellcheck="false"
          {{on "input" this.onInput}}
          {{on "focus" this.onFocus}}
          {{on "keydown" this.onKeydown}}
        />

        {{#if this.loading}}
          <div class="location-selector-inline__spinner">
            <div class="spinner small"></div>
          </div>
        {{else if this.searchTerm}}
          <button
            type="button"
            class="btn btn-flat btn-transparent location-selector-inline__clear"
            title={{i18n "location.geo.clear"}}
            {{on "click" this.clear}}
          >
            {{icon "xmark"}}
          </button>
        {{/if}}

        <DButton
          @icon="location-crosshairs"
          @title="location.geo.use_current_location"
          class="btn btn-flat btn-transparent location-current-btn"
          @action={{this.useCurrentLocation}}
        />
      </div>

      {{#if this.showResults}}
        <div class="location-selector-inline__results">
          {{#if this.results.length}}
            {{#each this.results as |result index|}}
              <button
                type="button"
                class={{concatClass
                  "location-selector-inline__result"
                  (if (eq index this.activeIndex) "--active")
                }}
                {{on "click" (fn this.select result)}}
                {{on "mouseenter" (fn this.setActive index)}}
              >
                {{this.displayText result}}
              </button>
            {{/each}}
          {{else if this.searched}}
            {{#unless this.loading}}
              <div class="location-selector-inline__empty">
                {{i18n "location.geo.no_results"}}
              </div>
            {{/unless}}
          {{/if}}

          {{#if this.providerLabel}}
            <div class="location-selector-inline__provider">
              {{trustedHtml
                (i18n "location.geo.desc" provider=this.providerLabel)
              }}
            </div>
          {{/if}}
        </div>
      {{/if}}
    </div>
  </template>
}
