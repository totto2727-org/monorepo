# MoonBit CLI JSON

> Document type: concrete MoonBit CLI implementation guidance.

## `ToJson` implementation

Every request body type must implement `ToJson` explicitly as a trait implementation. Do not use `derive(ToJson)` for request bodies.

Construct the request body from validated domain values. Do not pass `@admiral.Context`, command input structs, response DTOs, or generic `Json` into the request encoder.

Preferred order:

1. Express the JSON shape directly with `Json::object({ ... })` and Json-related types.
2. Use pattern matching plus Json-related types when variants are required.
3. Use `Map[String, Json]` only when omission vs. explicit `Json::null()` matters or when dynamic keys are unavoidable.

Example:

```moonbit
///|
impl ToJson for ScreenshotBody with fn to_json(self) -> Json {
  Json::object({
    "url": match self.url {
      Some(value) => value.to_json()
      None => Json::null()
    },
    "html": match self.html {
      Some(value) => value.to_json()
      None => Json::null()
    },
  })
}
```

If the remote API requires omission rather than `null`, isolate the unavoidable `Map[String, Json]` inside that one `to_json` implementation and document the API reason in a short comment. Do not introduce shared Map-building helpers.
