import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { hash } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import ComboBox from "discourse/select-kit/components/combo-box";
import { i18n } from "discourse-i18n";
import RegionGroupEditor from "./region-group-editor";

// Admin page: attach geographic coverage (center + radius points) to groups so
// members can discover and join the chapter(s) near them.
export default class AdminRegionGroups extends Component {
  @service site;

  @tracked groups = (this.args.regionGroups || []).map((g) => ({ ...g }));
  @tracked pickedGroupId = null;

  get availableGroups() {
    const existing = new Set(this.groups.map((g) => g.id));
    return (this.site.groups || []).filter((g) => !existing.has(g.id));
  }

  @action
  addGroup(id) {
    this.pickedGroupId = null;
    const group = (this.site.groups || []).find((g) => g.id === id);
    if (!group || this.groups.some((g) => g.id === id)) {
      return;
    }
    this.groups = [
      ...this.groups,
      {
        id: group.id,
        name: group.name,
        full_name: group.full_name,
        points: [],
      },
    ];
  }

  <template>
    <div class="region-groups-admin">
      <h2>{{i18n "location.admin.region_groups.title"}}</h2>
      <p class="region-groups-admin__intro">
        {{i18n "location.admin.region_groups.description"}}
      </p>

      <div class="region-groups-admin__add">
        <label>{{i18n "location.admin.region_groups.add_group"}}</label>
        <ComboBox
          @content={{this.availableGroups}}
          @value={{this.pickedGroupId}}
          @onChange={{this.addGroup}}
          @options={{hash
            filterable=true
            none="location.admin.region_groups.pick_group"
          }}
        />
      </div>

      {{#each this.groups as |group|}}
        <RegionGroupEditor @group={{group}} />
      {{else}}
        <p class="region-groups-admin__empty">
          {{i18n "location.admin.region_groups.none"}}
        </p>
      {{/each}}
    </div>
  </template>
}
