import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import LocationSelector from "./location-selector";

// Editor for one group's coverage points (center + radius, km). Precise centers
// (no @coarse), persisted via PUT /locations/admin/region-groups/:id.
export default class RegionGroupEditor extends Component {
  @service siteSettings;

  @tracked points = (this.args.group.points || []).map((p) => ({ ...p }));
  @tracked saving = false;
  @tracked saved = false;

  get heading() {
    return this.args.group.full_name || this.args.group.name;
  }

  @action
  pointLocation(point) {
    return point.label ? { address: point.label } : null;
  }

  @action
  addPoint() {
    this.saved = false;
    this.points = [
      ...this.points,
      {
        lat: null,
        lon: null,
        radius: this.siteSettings.location_region_default_radius,
        label: "",
      },
    ];
  }

  @action
  removePoint(index) {
    this.saved = false;
    this.points = this.points.filter((_, i) => i !== index);
  }

  @action
  onLocationChange(index, location) {
    this.saved = false;
    const next = [...this.points];
    if (location && location.lat && location.lon) {
      next[index] = {
        ...next[index],
        lat: location.lat,
        lon: location.lon,
        label: location.address || location.city || next[index].label,
      };
    } else {
      next[index] = { ...next[index], lat: null, lon: null };
    }
    this.points = next;
  }

  @action
  updateRadius(index, event) {
    this.saved = false;
    const next = [...this.points];
    next[index] = { ...next[index], radius: event.target.value };
    this.points = next;
  }

  @action
  async save() {
    this.saving = true;
    this.saved = false;
    try {
      const result = await ajax(
        `/locations/admin/region-groups/${this.args.group.id}`,
        {
          type: "PUT",
          data: { points: this.points.filter((p) => p.lat && p.lon) },
        }
      );
      this.points = (result.points || []).map((p) => ({ ...p }));
      this.saved = true;
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <div class="region-group-editor">
      <h3 class="region-group-editor__name">{{this.heading}}</h3>

      {{#each this.points as |point index|}}
        <div class="region-group-editor__point">
          <LocationSelector
            @location={{this.pointLocation point}}
            @onChangeCallback={{fn this.onLocationChange index}}
            @placeholder={{i18n
              "location.admin.region_groups.point_placeholder"
            }}
            class="region-group-editor__location"
          />
          <span class="region-group-editor__radius">
            <input
              type="number"
              min="1"
              step="1"
              value={{point.radius}}
              {{on "input" (fn this.updateRadius index)}}
            />
            {{i18n "location.admin.region_groups.km"}}
          </span>
          <DButton
            @icon="trash-can"
            @action={{fn this.removePoint index}}
            class="btn-flat region-group-editor__remove"
          />
        </div>
      {{/each}}

      <div class="region-group-editor__actions">
        <DButton
          @icon="plus"
          @label="location.admin.region_groups.add_point"
          @action={{this.addPoint}}
          class="btn-default"
        />
        <DButton
          @icon="check"
          @label="location.admin.region_groups.save"
          @action={{this.save}}
          @disabled={{this.saving}}
          class="btn-primary"
        />
        {{#if this.saved}}
          <span class="region-group-editor__saved">
            {{i18n "location.admin.region_groups.saved"}}
          </span>
        {{/if}}
      </div>
    </div>
  </template>
}
