/* global L */
import Component from "@glimmer/component";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { next } from "@ember/runloop";
import { service } from "@ember/service";
import getURL from "discourse/lib/get-url";
import { escapeExpression } from "discourse/lib/utilities";
import { i18n } from "discourse-i18n";
import { generateMap } from "../lib/map-utilities";

// A map of all regional chapters: a coverage circle + center marker per point,
// each linking to its group page.
export default class RegionsMap extends Component {
  @service siteSettings;

  @action
  setup(container) {
    const mapObjs = generateMap(this.siteSettings, {});
    container.appendChild(mapObjs.element);

    const map = mapObjs.map;
    const bounds = [];

    (this.args.regions || []).forEach((region) => {
      const name = region.group.full_name || region.group.name;
      const href = getURL(`/g/${region.group.name}`);
      const popup =
        `<strong>${escapeExpression(name)}</strong><br>` +
        `<a href="${href}">${escapeExpression(
          i18n("location.regions.view_group")
        )}</a>`;

      (region.points || []).forEach((p) => {
        const lat = parseFloat(p.lat);
        const lon = parseFloat(p.lon);
        const radiusKm =
          parseFloat(p.radius) ||
          this.siteSettings.location_region_default_radius;
        if (isNaN(lat) || isNaN(lon)) {
          return;
        }

        L.circle([lat, lon], {
          radius: radiusKm * 1000,
          color: "#3388ff",
          weight: 1,
          fillOpacity: 0.1,
        })
          .addTo(map)
          .bindPopup(popup);
        L.marker([lat, lon]).addTo(map).bindPopup(popup);
        bounds.push([lat, lon]);
      });
    });

    if (bounds.length) {
      map.fitBounds(bounds, { padding: [40, 40] });
    }
    next(() => map.invalidateSize());
  }

  <template>
    <div
      {{didInsert this.setup}}
      id="regions-map"
      class="locations-map regions-map"
    ></div>
  </template>
}
