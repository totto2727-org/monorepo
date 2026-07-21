# MoonBit CLI Option Definitions

> Document type: concrete MoonBit CLI implementation guidance.

## Option constants

Option names are part of the command contract. Define them as constants and use the constants everywhere: both in `admiral` definitions and when reading `@admiral.Context`.

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

Every runnable command definition accepts an async `@admiral.Context` callback and passes it as `run=Some(run)`. Every command runner is async, even when its current body performs no asynchronous operation. Group-only commands define `subcommands` and omit `run`; Admiral handles their help fallback.

MoonBit reports `unused_async` when an explicitly async example has no async operation. For a deliberately synchronous demonstration callback, call `@async.sleep(0)` once rather than changing the callback back to a synchronous type. Production callbacks should normally become async through their real I/O.

Do not scatter literal option strings through the file. Do not define a parallel dispatch table in `main.mbt`.
