import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminNpnLocationsRoute extends DiscourseRoute {
  model() {
    return ajax("/locations/admin/region-groups");
  }
}
