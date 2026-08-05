# OpenCode SDK for MoonBit

Embed the OpenCode agent in MoonBit workflows and applications through the installed [`opencode run --format json`](https://dev.opencode.ai/docs/cli/) command.

The public client shape intentionally follows `totto2727/codex-sdk`: create an `OpenCode` client, start or resume a `Thread`, then call `run` or `run_streamed`. Provider-specific options and events remain OpenCode-native because the CLIs do not share a wire protocol.

## Usage

```mbt check
///|
async fn example {
  let opencode = @opencode_sdk.OpenCode::OpenCode()
  let thread = opencode.start_thread(
    options=@opencode_sdk.ThreadOptions::ThreadOptions(
      model="opencode-go/deepseek-v4-flash",
    ),
  )
  let turn = thread.run(
    @opencode_sdk.Input::Prompt("Explain this repository in one paragraph."),
  )
  println(turn.final_response)
}
```

Add the package to a MoonBit project and import it with an alias:

```mbt
import {
  "totto2727/opencode-sdk@0.2.1",
}
```

```mbt
import {
  "totto2727/opencode-sdk" @opencode_sdk,
}
```

## Streaming

MoonBit uses an asynchronous callback in place of an async generator.

```mbt check
///|
async fn stream_example {
  let thread = @opencode_sdk.OpenCode::OpenCode().start_thread()
  thread.run_streamed(
    @opencode_sdk.Input::Prompt("Summarize the current changes."),
    async fn(event) {
      match event {
        @opencode_sdk.Text(text) => println(text.text)
        _ => ()
      }
      @async.pause()
    },
  )
}
```

`ThreadEvent` models the JSONL events emitted by the OpenCode CLI: completed text and reasoning parts, completed or failed tool calls, step start and finish records, and stream errors. Step-finish events retain cost and token usage, while `Thread::run` joins completed text parts into `Turn::final_response`.

## Options and lifecycle

`OpenCodeOptions` accepts an explicit executable path, an environment map, and recursively typed configuration serialized to `OPENCODE_CONFIG_CONTENT`. `ThreadOptions` forwards model, agent, working directory, variant, title, and thinking output through the corresponding official CLI flags, while `UserInputs` forwards local files with repeated `--file` flags.

The task that calls `run` or `run_streamed` owns the OpenCode subprocess. Cancelling that task hard-cancels and waits for the child process before control returns.

The managed-server implementation remains available separately as `totto2727/opencode-server-sdk`.
