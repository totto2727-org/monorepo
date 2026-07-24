# opencode-sdk

Native MoonBit SDK for starting and managing an [OpenCode server](https://opencode.ai/docs/server/).

The server lifecycle follows the handwritten TypeScript SDK contract. The SDK returns a configured [`DC-Z-lab/moonllm`](https://mooncakes.io/docs/DC-Z-lab/moonllm@0.1.0) builder when an application needs to communicate with the managed server, but it does not own or wrap the HTTP client.

## Usage

```mbt
@async.with_task_group() <| group => {
  let server = @opencode.create_opencode_server(group)
  try {
    let client = server.moonllm_config().build()
    let health = client.get_json("/global/health")
    println(@debug.to_string(health))
  } catch {
    err => {
      server.close()
      raise err
    }
  }
  server.close()
}
```

The task group must outlive the returned server. Call `Server::close` inside the task-group body on both success and failure; task-group defers run only after child tasks finish, while the managed server is itself a long-lived child task.
