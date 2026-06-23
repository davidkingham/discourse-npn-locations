// Maps a geocoded `geo_location.state` value to a subdivision flag image.
//
// Geocoding providers return the state/region inconsistently — Nominatim gives
// full names ("California"), others give abbreviations ("CA"). This module
// normalises both forms to the flag-file code we ship under
// public/images/subdivisionflags/<countryCode>/<code>.png.
//
// Only codes we actually ship an image for are returned, so callers never
// render a broken image. Add a new country by shipping its images and adding a
// map entry below.

// US states (plus DC) we ship a flag for. State flags come from flagcdn; the
// DC flag is from Wikimedia Commons.
const US_NAME_TO_CODE = {
  alabama: "al",
  alaska: "ak",
  arizona: "az",
  arkansas: "ar",
  california: "ca",
  colorado: "co",
  connecticut: "ct",
  delaware: "de",
  florida: "fl",
  georgia: "ga",
  hawaii: "hi",
  idaho: "id",
  illinois: "il",
  indiana: "in",
  iowa: "ia",
  kansas: "ks",
  kentucky: "ky",
  louisiana: "la",
  maine: "me",
  maryland: "md",
  massachusetts: "ma",
  michigan: "mi",
  minnesota: "mn",
  mississippi: "ms",
  missouri: "mo",
  montana: "mt",
  nebraska: "ne",
  nevada: "nv",
  "new hampshire": "nh",
  "new jersey": "nj",
  "new mexico": "nm",
  "new york": "ny",
  "north carolina": "nc",
  "north dakota": "nd",
  ohio: "oh",
  oklahoma: "ok",
  oregon: "or",
  pennsylvania: "pa",
  "rhode island": "ri",
  "south carolina": "sc",
  "south dakota": "sd",
  tennessee: "tn",
  texas: "tx",
  utah: "ut",
  vermont: "vt",
  virginia: "va",
  washington: "wa",
  "west virginia": "wv",
  wisconsin: "wi",
  wyoming: "wy",
  "district of columbia": "dc",
  "washington, d.c.": "dc",
  "washington dc": "dc",
};

// Title-cased display names keyed by code, for tooltips/alt text.
const US_CODE_TO_NAME = Object.entries(US_NAME_TO_CODE).reduce(
  (acc, [name, code]) => {
    acc[code] = name.replace(/\b\w/g, (c) => c.toUpperCase());
    return acc;
  },
  {}
);
// Proper-noun overrides where naive title-casing is wrong.
US_CODE_TO_NAME.dc = "District of Columbia";

// Per-country registry. Each entry resolves a raw state string to a flag code
// and a display name.
const COUNTRIES = {
  us: {
    nameToCode: US_NAME_TO_CODE,
    codeToName: US_CODE_TO_NAME,
  },
};

// Returns { countryCode, code, name } when a subdivision flag exists, else null.
export function subdivisionFlagInfo(countryCode, state) {
  if (!countryCode || !state) {
    return null;
  }

  const cc = String(countryCode).toLowerCase().trim();
  const country = COUNTRIES[cc];
  if (!country) {
    return null;
  }

  const key = String(state).toLowerCase().trim();

  // Accept either a full name ("California") or an abbreviation ("CA").
  let code = country.nameToCode[key];
  if (!code && country.codeToName[key]) {
    code = key;
  }
  if (!code) {
    return null;
  }

  return { countryCode: cc, code, name: country.codeToName[code] };
}

export function hasSubdivisionFlags(countryCode) {
  return Boolean(
    COUNTRIES[
      String(countryCode || "")
        .toLowerCase()
        .trim()
    ]
  );
}
