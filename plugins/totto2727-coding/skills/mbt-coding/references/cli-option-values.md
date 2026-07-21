# MoonBit CLI Option Values

> Document type: concrete MoonBit CLI implementation guidance.

## Options struct conversion

The options conversion function is the boundary from raw CLI/config/env input to typed data. It must:

- read `@admiral.Context` using option constants, and keep all raw context access inside this command-local conversion step
- prefer `get_bool`, `get_string`, `get_string_required`, `get_int`, `get_int_required`, and `get_strings`; read `values` directly only when the command must validate exact cardinality or distinguish a missing value from an empty collection
- resolve environment variable fallbacks such as credentials
- raise immediately when a required value is missing or malformed
- preserve user-provided values without domain processing
- return a command-local input struct that is validated before it reaches the domain operation

It must not:

- build request JSON
- parse HTML content or other domain payloads
- make HTTP requests
- hide command-specific requirements behind generic helpers

For commands that call an external API, keep the types separate: `@admiral.Context -> command input -> domain operation -> request body -> Json`. The command input represents user intent and must not double as the remote request body. See [`boundary-conversion.md`](boundary-conversion.md).

Example:

```moonbit
///|
enum PageInput {
  Url(String)
  HtmlFile(String)
}

///|
struct ScreenshotOptions {
  account_id : String
  api_token : String
  input : PageInput
  output : String
}

///|
fn screenshot_options(
  context : @admiral.Context,
) -> ScreenshotOptions raise {
  let account_id = match context.values.get(screenshot_account_id_option) {
    Some(values) => match values {
      [value] => value
      _ => fail("account-id accepts exactly one value")
    }
    _ => match @env.get_env_var(cloudflare_account_id_env) {
      Some(value) => value
      None => fail("account-id is required. Set CLOUDFLARE_ACCOUNT_ID or pass --account-id")
    }
  }
  let api_token = match context.values.get(screenshot_api_token_option) {
    Some(values) => match values {
      [value] => value
      _ => fail("api-token accepts exactly one value")
    }
    _ => match @env.get_env_var(cloudflare_api_token_env) {
      Some(value) => value
      None => fail("api-token is required. Set CLOUDFLARE_API_TOKEN or pass --api-token")
    }
  }
  let input = match (
    context.values.get(screenshot_url_option),
    context.values.get(screenshot_html_option),
  ) {
    (Some([value]), _) => Url(value)
    (_, Some([path])) => HtmlFile(path)
    (Some(_), _) => fail("url accepts exactly one value")
    (_, Some(_)) => fail("html accepts exactly one value")
    _ => fail("Either --url or --html is required")
  }
  let output_values = match context.values.get(screenshot_output_option) {
    Some(values) => values
    None => fail("missing required option: output")
  }
  let output = match output_values {
    [value] => value
    _ => fail("output accepts exactly one value")
  }
  { account_id, api_token, input, output }
}
```

For “one of these inputs is required” cases, use an enum. Do not model the state as two independent optional fields in the options struct when only one valid state exists.

Handle values that the command definition marks as required with an explicit total match at the options-conversion boundary, then immediately total-match the resulting array. Do not use partial array destructuring such as `[value, ..]` after required extraction. Keep fallback chains, such as command flag to environment variable to error, as explicit matches so the command contract stays clear.
