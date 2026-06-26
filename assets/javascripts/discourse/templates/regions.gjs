import { i18n } from "discourse-i18n";
import RegionsMap from "../components/regions-map";

export default <template>
  <div class="regions-page">
    <h1 class="regions-page__title">{{i18n "location.regions.title"}}</h1>
    <RegionsMap @regions={{@model.regions}} />
  </div>
</template>
