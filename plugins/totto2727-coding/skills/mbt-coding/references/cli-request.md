# MoonBit CLI Request

> Document type: concrete MoonBit CLI implementation guidance.

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

Only the async command callback receives raw `@admiral.Context`, and it should pass that context directly to the command-local options conversion. After that conversion, request/body helpers accept typed options and body values. They must not re-resolve credentials, read raw context, or re-validate required options. If a required value can be missing after options conversion, the conversion is too weak.
