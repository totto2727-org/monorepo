# opencode-server-sdk

Native MoonBit SDK for starting and managing an [OpenCode server](https://opencode.ai/docs/server/).

The server lifecycle follows the handwritten TypeScript SDK contract. This package owns only the server process and its announced URL; callers may use the HTTP client of their choice.

## Usage

```mbt
@async.with_task_group() <| group => {
  let server = @opencode.create_opencode_server(group)
  println(server.url())
  server.close()
}
```

The task group must outlive the returned server. Call `Server::close` inside the task-group body on both success and failure; task-group defers run only after child tasks finish, while the managed server is itself a long-lived child task.

Use `totto2727/opencode-sdk` instead when the application should run agent turns through the `opencode` CLI.
