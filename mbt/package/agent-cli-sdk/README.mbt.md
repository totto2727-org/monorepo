# Agent CLI SDK

`agent-cli-sdk` provides the shared native process lifecycle for MoonBit SDKs that run agent CLIs and consume JSONL events.

Provider SDKs remain responsible for building CLI arguments and environment variables, defining provider-specific event types with `FromJson`, and aggregating turns. This package owns stdin delivery, ordered JSONL parsing and typed decoding, stderr capture, exit status reporting, callback-requested termination, and cancellation-safe child cleanup.

```moonbit
struct Event {
  message : String
} derive(FromJson)

let result = @agent_cli.run(
  @agent_cli.Invocation::new(
    command="agent",
    arguments=["run", "--format", "json"],
    input="Hello",
  ),
  async fn(event : Event) {
    println(event.message)
    true
  },
)
```
