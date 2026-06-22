import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
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
  _autoPick = false;
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
    return this.isOpen && (this.loading || this.results.length || this.searched);
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
    this._autoPick = false;

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
      if (term !== this.searchTerm.trim() && !this._autoPick) {
        return;
      }

      this.results = (r?.locations || []).filter((l) => l && !l.provider);
      this.provider =
        r?.provider || this.siteSettings.location_geocoding_provider;
      this.searched = true;
      this.loading = false;

      if (this._autoPick && this.results.length) {
        this._autoPick = false;
        this.select(this.results[0]);
      }
    } catch (e) {
      this.loading = false;
      this.results = [];
      this.searched = true;
      this.args.searchError?.(e);
    }
  }

  @action
  select(location) {
    this.args.onChangeCallback?.(location);
    this.searchTerm = this.displayText(location);
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
  useCurrentLocation() {
    if (!navigator.geolocation) {
      return;
    }
    this._autoPick = true;
    this.loading = true;
    this.isOpen = true;

    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        const term = `${coords.latitude}, ${coords.longitude}`;
        this.searchTerm = term;
        this.search(term);
      },
      () => {
        this._autoPick = false;
        this.loading = false;
      }
    );
  }

  <template>
    <div
      class="location-selector-wrapper location-selector-inline"
      {{didInsert this.setup}}
      {{willDestroy this.teardown}}
      ...attributes
    >
      <div class="location-selector-inline__field">
        {{icon "magnifying-glass" class="location-selector-inline__search-icon"}}
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
              {{htmlSafe (i18n "location.geo.desc" provider=this.providerLabel)}}
            </div>
          {{/if}}
        </div>
      {{/if}}
    </div>
  </template>
}
