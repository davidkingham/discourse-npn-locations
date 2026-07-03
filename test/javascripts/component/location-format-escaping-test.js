import { render } from "@ember/test-helpers";
import { hbs } from "ember-cli-htmlbars";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";

// Regression: the location-format / geo-location-format helpers used to wrap
// their output in trusted HTML, so a malicious location name (free text typed
// by a topic author) executed as markup wherever the location label rendered.
// The formatters only ever emit plain text, so the helpers must return a plain
// string that Glimmer escapes.
module(
  "Discourse Locations | Component | location-format escaping",
  function (hooks) {
    setupRenderingTest(hooks);

    test("escapes HTML in a topic location name", async function (assert) {
      this.location = { name: '<img src=x onerror="window.__xss=1">' };

      await render(hbs`<span class="out">{{locationFormat this.location}}</span>`);

      assert.dom(".out img").doesNotExist("markup in the name is not rendered");
      assert
        .dom(".out")
        .hasText(
          '<img src=x onerror="window.__xss=1">',
          "the name is shown as escaped text"
        );
    });

    test("escapes HTML in a geo location's fields", async function (assert) {
      this.geo = { city: "<b>Nowhere</b>", address: "<b>Nowhere</b>" };

      await render(
        hbs`<span class="out">{{geoLocationFormat this.geo}}</span>`
      );

      assert.dom(".out b").doesNotExist("markup in geo fields is not rendered");
    });
  }
);
