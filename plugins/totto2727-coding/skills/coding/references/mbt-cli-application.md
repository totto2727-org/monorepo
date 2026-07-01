# MoonBit CLI Application Implementation

Use this guide when implementing MoonBit CLI applications. The `bw`
package is the reference implementation for the overall shape: one command file
per CLI command, `admiral` for argument definitions, `moonbitlang/async` for
native async execution, explicit option/body types, and request code that only
accepts typed data.

This document is normative for new CLI work. If an older `bw` detail differs
from this guide, prefer this guide and update the implementation.

## Required command pipeline

Every command must follow this sequence:

1. **Option name constants** — define every CLI option name once.
2. **`admiral` command definition** — use only those constants in the option
   definitions.
3. **Options struct** — convert `@argparse.Matches` into a typed command-local
   options struct.
4. **Body struct** — convert the options struct into the exact request body
   type.
5. **Request** — send `body.to_json()` to the HTTP layer.

Do not skip the options struct. Do not build JSON directly from `Matches`.

## File organization

Split CLI implementations by command:

```text
src/
  main.mbt                  # command list + dispatch only
  auth.mbt                  # environment variable names only
  http_client.mbt           # HTTP send / response status boundary
  output.mbt                # output writing helpers
  command_content.mbt       # content command
  command_markdown.mbt      # markdown command
  command_screenshot.mbt    # screenshot command
  ...
```

`main.mbt` should stay small: build the command list, parse once, dispatch to a
command runner. Command-specific parsing, validation, body construction, and
request invocation belong in the command file.

## Option constants

Option names are part of the command contract. Define them as constants and use
the constants everywhere: both in `admiral` definitions and when reading
`Matches`.

```moonbit
///|
let screenshot_account_id_option = "account-id"
let screenshot_url_option = "url"
let screenshot_html_option = "html"
let screenshot_output_option = "output"

///|
fn screenshot_command_def() -> @admiral.CommandDef {
  @admiral.command(name="screenshot", description="Capture a screenshot", options=[
    @admiral.string(screenshot_account_id_option, description="Cloudflare account ID"),
    @admiral.string(screenshot_url_option, description="Target URL"),
    @admiral.string(screenshot_html_option, description="Path to local HTML file"),
    @admiral.string(screenshot_output_option, short='o', description="Output file path", required=true),
  ])
}
```

Do not scatter literal option strings through the file.

## Options struct conversion

The options conversion function is the boundary from raw CLI/config/env input to
typed data. It must:

- read `@argparse.Matches` using option constants
- resolve environment variable fallbacks such as credentials
- raise immediately when a required value is missing or malformed
- preserve user-provided values without domain processing
- return a command-local options struct

It must not:

- build request JSON
- parse HTML content or other domain payloads
- make HTTP requests
- hide command-specific requirements behind generic helpers

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
async fn screenshot_options(matches : @argparse.Matches) -> ScreenshotOptions {
  let account_id = match matches.values.get(screenshot_account_id_option) {
    Some([value, ..]) => value
    _ => match @env.get_env_var(cloudflare_account_id_env) {
      Some(value) => value
      None => fail("account-id is required. Set CLOUDFLARE_ACCOUNT_ID or pass --account-id")
    }
  }
  let api_token = match matches.values.get(screenshot_api_token_option) {
    Some([value, ..]) => value
    _ => match @env.get_env_var(cloudflare_api_token_env) {
      Some(value) => value
      None => fail("api-token is required. Set CLOUDFLARE_API_TOKEN or pass --api-token")
    }
  }
  let input = match (matches.values.get(screenshot_url_option), matches.values.get(screenshot_html_option)) {
    (Some([value, ..]), _) => Url(value)
    (_, Some([path, ..])) => HtmlFile(path)
    _ => fail("Either --url or --html is required")
  }
  let output = match matches.values.get(screenshot_output_option) {
    Some([value, ..]) => value
    _ => fail("missing required option: output")
  }
  { account_id, api_token, input, output }
}
```

For “one of these inputs is required” cases, use an enum. Do not model the state
as two independent optional fields in the options struct when only one valid
state exists.

## Body struct conversion

The body struct represents the request payload shape. Convert options into the
body after option validation. Domain processing required to build the payload,
such as reading an HTML file into an `html` body field, belongs here or in the
command runner immediately before this conversion, not in options parsing.

```moonbit
///|
struct ScreenshotBody {
  url : String?
  html : String?
}

///|
async fn ScreenshotBody::from_options(options : ScreenshotOptions) -> ScreenshotBody {
  match options.input {
    Url(value) => { url: Some(value), html: None }
    HtmlFile(path) => { url: None, html: Some(@fs.read_file(path).text()) }
  }
}
```

Keep body conversion command-specific. Avoid generic `build_body`,
`add_bool_nested`, `add_string_nested`, or “JSON patch” helpers.

## `ToJson` implementation

Every request body type must implement `ToJson` explicitly as a trait
implementation. Do not use `derive(ToJson)` for request bodies.

Preferred order:

1. Express the JSON shape directly with `Json::object({ ... })` and Json-related
   types.
2. Use pattern matching plus Json-related types when variants are required.
3. Use `Map[String, Json]` only when the JSON structure cannot be represented
   directly.

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

If the remote API requires omission rather than `null`, isolate the unavoidable
`Map[String, Json]` inside that one `to_json` implementation and document the API
reason in a short comment. Do not introduce shared Map-building helpers.

## Request execution

The runner should be straightforward:

```moonbit
///|
async fn run_screenshot(matches : @argparse.Matches) -> Unit {
  let options = screenshot_options(matches)
  let body = ScreenshotBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/screenshot",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  write_binary(options.output, data, "Screenshot")
}
```

The runner must not re-resolve credentials or re-validate required options. If a
required value can be missing in the runner, the options conversion is too weak.

## JSON responses

Treat JSON responses as JSON responses by default: print or write the response
body unchanged when no internal decision depends on its fields.

Only parse JSON when the command needs to inspect it. When parsing is required:

1. parse at the smallest possible scope
2. immediately convert into a command-specific typed struct/enum
3. continue with that typed value
4. do not let raw `Json` leak through the rest of the command

The conversion style should mirror options conversion: raw input at the boundary,
typed value inside the implementation.

## Anti-patterns

- Directly constructing request JSON from `@argparse.Matches`.
- Shared generic body builders like `add_bool_nested` or `add_string_nested`.
- Keeping mutually exclusive states as several optional fields in `Options`.
- Resolving environment variables in the runner instead of options conversion.
- Parsing files or domain payloads while creating the options struct.
- Using `derive(ToJson)` for request body wire types.
- Using `Map[String, Json]` as the default JSON construction strategy.
- Adding aliases (`#alias` or type aliases) unless the alternate name is actually
  part of the public API and used by callers.
