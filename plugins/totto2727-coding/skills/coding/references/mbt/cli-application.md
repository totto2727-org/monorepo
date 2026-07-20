# MoonBit CLI Application Implementation

Use this guide when implementing MoonBit CLI applications. Use the current
`totto2727/admiral` API for the complete CLI lifecycle: command definition,
argument parsing, help fallback, async callback execution, and error
propagation. Do not combine Admiral definitions with a separate manual
`argparse` dispatcher.

## Source-of-truth priority

Apply CLI rules in this order:

1. The `totto2727/admiral` version pinned by the target module and its current
   public API.
2. The current Admiral-based implementations under `mbt/app/c-plugin`,
   `mbt/app/bw`, and `mbt/app/wt`.
3. Examples in this guide.

If this guide conflicts with the pinned Admiral API or those current
implementations, follow Admiral and update this guide. Never restore direct
`@argparse.Command` construction, manual parsing, or manual dispatch in
`main.mbt` to preserve an older pattern.

For the current repository baseline, depend on `totto2727/admiral@0.2.1`. Keep
the package name and version consistent in `moon.mod`, `moon.pkg`, and any
generated compatibility manifest such as `package.nix`.

## Required command pipeline

Every command must follow the first three steps. Request-backed commands also
follow steps four and five:

1. **Option name constants** — define every CLI option name once.
2. **`admiral` command definition** — use only those constants in the option
   definitions.
3. **Options struct** — convert `@admiral.Context` into a typed command-local
   options struct.
4. **Body struct** — convert the options struct into the exact request body
   type.
5. **Request** — send `body.to_json()` to the HTTP layer.

Do not skip the options struct. Do not build JSON directly from
`@admiral.Context`.

## File organization

Split CLI implementations by command:

```text
src/
  main.mbt                  # Admiral app construction + app.run() only
  auth.mbt                  # environment variable names only
  http_client.mbt           # HTTP send / response status boundary
  output.mbt                # output writing helpers
  command_content.mbt       # content command
  command_markdown.mbt      # markdown command
  command_screenshot.mbt    # screenshot command
  ...
```

`main.mbt` should only construct the Admiral app and call `app.run()`. Admiral
owns parsing and dispatch. Command-specific validation, options conversion,
body construction, and execution belong in the command file.

```moonbit
///|
async fn main {
  let app = @admiral.cli(
    name="myapp",
    description="My CLI application",
    commands=[
      status_command_def(run_status),
      @admiral.command(
        name="config",
        description="Manage configuration",
        subcommands=[
          config_show_command_def(run_config_show),
          config_set_command_def(run_config_set),
        ],
      ),
    ],
  )
  app.run()
}
```

Do not add a task group, background spawn, explicit `@env.args()` help
rewrite, `help_path`, manual parse function, or dispatch match around
`app.run()`. Admiral displays the relevant help when no runnable command or
required subcommand is supplied. Unknown commands, invalid options, and errors
from command callbacks remain errors.

## Option constants

Option names are part of the command contract. Define them as constants and use
the constants everywhere: both in `admiral` definitions and when reading
`@admiral.Context`.

```moonbit
///|
let screenshot_account_id_option = "account-id"
let screenshot_url_option = "url"
let screenshot_html_option = "html"
let screenshot_output_option = "output"

///|
fn screenshot_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="screenshot",
    description="Capture a screenshot",
    options=[
      @admiral.string(
        screenshot_account_id_option,
        description="Cloudflare account ID",
      ),
      @admiral.string(screenshot_url_option, description="Target URL"),
      @admiral.string(
        screenshot_html_option,
        description="Path to local HTML file",
      ),
      @admiral.string(
        screenshot_output_option,
        short='o',
        description="Output file path",
        required=true,
      ),
    ],
    run=Some(run),
  )
}
```

Every runnable command definition accepts an async `@admiral.Context` callback
and passes it as `run=Some(run)`. Every command runner is async, even when its
current body performs no asynchronous operation. Group-only commands define
`subcommands` and omit `run`; Admiral handles their help fallback.

MoonBit reports `unused_async` when an explicitly async example has no async
operation. For a deliberately synchronous demonstration callback, call
`@async.sleep(0)` once rather than changing the callback back to a synchronous
type. Production callbacks should normally become async through their real I/O.

Do not scatter literal option strings through the file. Do not define a
parallel dispatch table in `main.mbt`.

## Options struct conversion

The options conversion function is the boundary from raw CLI/config/env input to
typed data. It must:

- read `@admiral.Context` using option constants, and keep all raw context
  access inside this command-local conversion step
- prefer `get_bool`, `get_string`, `get_string_required`, `get_int`,
  `get_int_required`, and `get_strings`; read `values` directly only when the
  command must validate exact cardinality or distinguish a missing value from
  an empty collection
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

For “one of these inputs is required” cases, use an enum. Do not model the state
as two independent optional fields in the options struct when only one valid
state exists.

Handle values that the command definition marks as required with an explicit
total match at the options-conversion boundary, then immediately total-match the
resulting array. Do not use partial array destructuring such as `[value, ..]`
after required extraction. Keep fallback chains, such as command flag to
environment variable to error, as explicit matches so the command contract stays
clear.

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
3. Use `Map[String, Json]` only when omission vs. explicit `Json::null()`
   matters or when dynamic keys are unavoidable.

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
async fn run_screenshot(context : @admiral.Context) -> Unit {
  let options = screenshot_options(context)
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

Only the async command callback receives raw `@admiral.Context`, and it should
pass that context directly to the command-local options conversion. After that
conversion, request/body helpers accept typed options and body values. They
must not re-resolve credentials, read raw context, or re-validate required
options. If a required value can be missing after options conversion, the
conversion is too weak.

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

- Importing or constructing `@argparse.Command` in an Admiral-based CLI.
- Calling `parse()` or manually matching subcommands in `main.mbt`.
- Wrapping async command execution in a task group or background spawn.
- Reimplementing root or subcommand help fallback around `app.run()`.
- Using synchronous command callbacks; `run` callbacks are async by default.
- Directly constructing request JSON from `@admiral.Context`.
- Reading raw `@admiral.Context` outside command-local options conversion and
  the async command entrypoint that invokes it.
- Shared generic body builders like `add_bool_nested` or `add_string_nested`.
- Keeping mutually exclusive states as several optional fields in `Options`.
- Resolving environment variables in the runner instead of options conversion.
- Parsing files or domain payloads while creating the options struct.
- Using `derive(ToJson)` for request body wire types.
- Using `Map[String, Json]` as the default JSON construction strategy.
- Replacing explicit required-value handling or meaningful fallback chains with opaque error-extraction helpers.
- Destructuring required option arrays with `[value, ..]` after extraction.
- Adding aliases (`#alias` or type aliases) unless the alternate name is actually
  part of the public API and used by callers.
