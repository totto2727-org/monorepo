# Codex SDK for MoonBit

Embed the Codex agent in MoonBit workflows and applications.

This package is a direct MoonBit port of the official [`@openai/codex-sdk`](https://github.com/openai/codex/tree/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript). It wraps the `codex` CLI and exchanges JSONL events over stdin and stdout.

## Workspace usage

```mbt
import {
  "totto2727/codex-sdk" @codex_sdk,
}
```

The native `codex` executable must be available on `PATH`, or supplied with `codex_path_override`.

## Quickstart

```mbt
async fn main {
  let codex = @codex_sdk.Codex::Codex()
  let thread = codex.start_thread()
  let turn = thread.run(
    @codex_sdk.Input::Prompt("Diagnose the test failure and propose a fix"),
  )
  println(turn.final_response)
}
```

Call `run` repeatedly on the same `Thread` value to continue that conversation.

## Streaming responses

MoonBit uses an asynchronous callback in place of TypeScript's `AsyncGenerator`. The callback receives the same structured event variants and remains inside the task that owns the Codex subprocess.

```mbt
thread.run_streamed(
  @codex_sdk.Input::Prompt("Diagnose the test failure"),
  async event => {
    match event {
      ItemCompleted(completed) => println("\{completed.item}")
      TurnCompleted(completed) => println("\{completed.usage}")
      _ => ()
    }
  },
)
```

Cancelling the MoonBit task that runs `run` or `run_streamed` cancels the Codex subprocess, which is the native equivalent of passing an `AbortSignal`.

## Structured output

Pass a JSON object as the per-turn output schema. The SDK writes it to a temporary file and forwards the path through `--output-schema`.

```mbt
let schema = Json::object({
  "type": "object",
  "properties": {
    "summary": Json::object({ "type": "string" }),
  },
  "required": ["summary"],
  "additionalProperties": false,
})
let turn = thread.run(
  Prompt("Summarize repository status"),
  turn_options=@codex_sdk.TurnOptions::TurnOptions(output_schema=schema),
)
```

## TypeScript parity

The public event, item, option, thread, and turn models follow the official TypeScript SDK. MoonBit paths use `moonbitlang/x/path.Path`, task cancellation replaces `AbortSignal`, and streaming uses an async callback because the pinned MoonBit async runtime does not expose an async-generator type. Node's optional-package binary lookup is replaced by `PATH` lookup because a MoonBit package has no Node module-resolution context.

## Tests

Run the native package suite through the repository task runner:

```sh
vp run --filter @package/codex-sdk test
```

The upstream `abort`, `exec`, `run`, and `runStreamed` cases are ported against a native fake Codex executable that records arguments, environment variables, stdin, schemas, JSONL events, process exits, and cancellation. The Node-only optional-package layout cases are represented by MoonBit-native coverage for an explicit executable override, inherited `PATH`, exact caller-provided `PATH`, and preservation of the Windows `Path` key.
