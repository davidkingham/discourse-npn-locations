import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

// Adds a "Regions" link to the sidebar Community section when regional groups
// are enabled, for easy discovery of the regions map.
export default {
  name: "npn-locations-regions-nav",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.location_region_groups_enabled) {
      return;
    }

    withPluginApi((api) => {
      api.addCommunitySectionLink({
        name: "regions",
        route: "regions",
        title: i18n("location.regions.title"),
        text: i18n("location.regions.nav"),
        icon: "location-dot",
      });
    });
  },
};
