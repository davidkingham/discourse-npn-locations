import * as emberTemplate from "@ember/template";

// `trustHTML` exists on recent Discourse; `htmlSafe` is the long-standing API
// still present on stable. Prefer the former, fall back to the latter, so the
// plugin works on both the `latest` and `stable` Discourse branches.
const trustedHtml = emberTemplate.trustHTML ?? emberTemplate.htmlSafe;

export default trustedHtml;
export { trustedHtml };
