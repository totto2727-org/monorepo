# MoonBit CLI Option Values

> Document type: concrete MoonBit CLI implementation guidance.

## Options struct conversion

The options conversion function is the boundary from raw CLI/config/env input to typed data. It must:

- read `@admiral.Context` using typed option definitions, and keep all context access inside this command-local conversion step
- prefer `get_bool`, `get_string`, `get_string_required`, `get_int`, `get_int_required`, and `get_strings`; read `values` directly only when the command must validate exact cardinality, distinguish a missing value from an empty collection, or distinguish an absent optional numeric option from a provided invalid number that an optional numeric getter reports as `None`
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
  let account_id = match context.get_string(screenshot_account_id_option) {
    Some(value) => value
    None => match @env.get_env_var(cloudflare_account_id_env) {
      Some(value) => value
      None => fail("account-id is required. Set CLOUDFLARE_ACCOUNT_ID or pass --account-id")
    }
  }
  let api_token = match context.get_string(screenshot_api_token_option) {
    Some(value) => value
    None => match @env.get_env_var(cloudflare_api_token_env) {
      Some(value) => value
      None => fail("api-token is required. Set CLOUDFLARE_API_TOKEN or pass --api-token")
    }
  }
  let input = match (
    context.get_string(screenshot_url_option),
    context.get_string(screenshot_html_option),
  ) {
    (Some(value), _) => Url(value)
    (_, Some(path)) => HtmlFile(path)
    _ => fail("Either --url or --html is required")
  }
  let output = context.get_string_required(screenshot_output_option)
  { account_id, api_token, input, output }
}
```

For “one of these inputs is required” cases, use an enum. Do not model the state as two independent optional fields in the options struct when only one valid state exists.

Handle values that the command definition marks as required with the matching typed required getter at the options-conversion boundary. Keep fallback chains, such as command flag to environment variable to error, as explicit matches so the command contract stays clear.
