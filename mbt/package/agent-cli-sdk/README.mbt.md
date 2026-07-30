# Agent CLI SDK

`agent-cli-sdk` provides the shared native process lifecycle for MoonBit SDKs that run agent CLIs and consume JSONL events.

Provider SDKs remain responsible for building CLI arguments and environment variables, decoding provider-specific events, and aggregating turns. This package owns stdin delivery, ordered JSONL parsing, stderr capture, exit status reporting, callback-requested termination, and cancellation-safe child cleanup.

```moonbit
let result = @agent_cli.run(
  @agent_cli.Invocation::new(
    command="agent",
    arguments=["run", "--format", "json"],
    input="Hello",
  ),
  async fn(line) {
    println(line.value.stringify())
    true
  },
)
```
