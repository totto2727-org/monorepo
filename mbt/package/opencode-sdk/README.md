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

## CLI examples

The example executable starts a managed OpenCode server, uses the SDK's `moonllm_config` builder, and closes the server before its task group exits. OpenCode uses the provider and model configured in the user's environment.

Translate text into English without allowing any tools:

```bash
moon run --target native mbt/package/opencode-sdk/src/examples/cli -- translate 'MoonBitでOpenCode SDKを実装しています。'
```

Fetch an HTTP or HTTPS page with OpenCode's `webfetch` tool and summarize it as Markdown:

```bash
moon run --target native mbt/package/opencode-sdk/src/examples/cli -- summarize-url https://example.com
```

The translation session denies every tool. The URL summarization session also denies every tool by default, then allows only `webfetch` through OpenCode's [permission rules](https://opencode.ai/docs/permissions/).
