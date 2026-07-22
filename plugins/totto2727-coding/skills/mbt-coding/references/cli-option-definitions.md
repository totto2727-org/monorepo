# MoonBit CLI Option Definitions

> Document type: concrete MoonBit CLI implementation guidance.

## Option constants

Option definitions are part of the command contract. Construct each definition once with its concrete `OptionDef[T]` type, then use the same value both in the Admiral command definition and when reading `@admiral.Context`. MoonBit requires explicit type annotations for top-level declarations.

```moonbit
///|
let screenshot_account_id_option : @admiral.OptionDef[String] =
  @admiral.string("account-id", description="Cloudflare account ID")

///|
let screenshot_api_token_option : @admiral.OptionDef[String] = @admiral.string(
  "api-token",
  description="Cloudflare API token",
)

///|
let screenshot_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
)

///|
let screenshot_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
)

///|
let screenshot_output_option : @admiral.OptionDef[String] = @admiral.string(
  "output",
  short='o',
  description="Output file path",
  required=true,
)

///|
fn screenshot_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="screenshot",
    description="Capture a screenshot",
    options=[
      screenshot_account_id_option,
      screenshot_api_token_option,
      screenshot_url_option,
      screenshot_html_option,
      screenshot_output_option,
    ],
    run=Some(run),
  )
}
```

Every runnable command definition accepts an async `@admiral.Context` callback and passes it as `run=Some(run)`. Every command runner is async, even when its current body performs no asynchronous operation. Group-only commands define `subcommands` and omit `run`; Admiral handles their help fallback.

MoonBit reports `unused_async` when an explicitly async example has no async operation. For a deliberately synchronous demonstration callback, call `@async.sleep(0)` once rather than changing the callback back to a synchronous type. Production callbacks should normally become async through their real I/O.

Do not retain a parallel set of string option names or scatter literal option strings through the file. Do not define a parallel dispatch table in `main.mbt`.
