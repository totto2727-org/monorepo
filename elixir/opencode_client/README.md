# OpencodeClient

Generated Elixir client modules for OpenCode Server.

This package treats OpenAPI code generation as the source of truth. Endpoint modules and schema modules are generated with [`oapi_generator`](https://hex.pm/packages/oapi_generator) from `opencode-openapi.json`; do not hand-write endpoint wrappers that duplicate generated operations.

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:opencode_client, path: "../package/opencode_client"}
  ]
end
```

## Usage

```elixir
{:ok, session} = OpencodeClient.Generated.Session.session_create(%{
  title: "My Session",
  directory: "/path/to/project"
})

# Send prompt asynchronously
{:ok, _} = OpencodeClient.Generated.Session.session_prompt_async(session.id, %{
  parts: [%{type: "text", text: "Hello, implement a feature"}]
})

# Stream Server-Sent Events. SSE frame parsing is handled by req_server_sent_events.
{:ok, events} = OpencodeClient.EventStream.stream()

Enum.each(events, fn event ->
  IO.inspect(event)
end)

# Delete session
{:ok, _} = OpencodeClient.Generated.Session.session_delete(session.id)
```

## Modules

- `OpencodeClient.Generated.Session` — generated session operations
- `OpencodeClient.Generated.*` — generated OpenCode schemas and operation groups
- `OpencodeClient.Client` — Req transport for generated operation request maps
- `OpencodeClient.EventStream` — `/event` SSE stream helper backed by `req_server_sent_events`

## Dependencies

- `req` — HTTP client
- `jason` — JSON encoding/decoding
- `req_server_sent_events` — Server-Sent Events frame parsing for Req streams
- `oapi_generator` — OpenAPI code generator, dev-only

## Regeneration

The generated modules are committed, but must be regenerated from the OpenCode OpenAPI schema when the schema changes.

### Fetch the OpenAPI schema

Start OpenCode Server, then refresh the schema:

```bash
opencode serve
curl http://localhost:4096/doc -o opencode-openapi.json
```

### Generate code

```bash
mix deps.get
mix api.gen default opencode-openapi.json
```

Generation is configured in `config/config.exs`:

```elixir
config :oapi_generator,
  default: [
    output: [
      base_module: OpencodeClient.Generated,
      default_client: OpencodeClient.Client,
      location: "lib/opencode_client/generated"
    ]
  ]
```

### Generator choice

`oapi_generator` is the primary generator because it is Elixir-native and emits operation modules that delegate requests through a configurable `client.request/1` boundary. That boundary keeps HTTP transport and SSE support separate from generated endpoint definitions.

| Tool | Status | Notes |
|---|---|---|
| [`oapi_generator`](https://hex.pm/packages/oapi_generator) | Primary | Elixir-native Mix task, generated modules committed under `lib/opencode_client/generated` |
| [`openapi-generator` Elixir](https://openapi-generator.tech/docs/generators/elixir/) | Fallback | Use only if `oapi_generator` can no longer process the schema |
| [`openapi_codegen`](https://hex.pm/packages/openapi_codegen) | Fallback | Re-evaluate if it supports the current OpenCode schema |

## SSE

OpenCode exposes `/event` as a Server-Sent Events stream. This package uses [`req_server_sent_events`](https://hex.pm/packages/req_server_sent_events) for SSE frame parsing instead of maintaining a custom parser.

```elixir
{:ok, events} = OpencodeClient.EventStream.stream(
  base_url: "http://localhost:4096",
  auth: {:basic, "opencode", "password"}
)

Enum.each(events, fn %{type: type, data: data} ->
  IO.inspect({type, data})
end)
```

`OpencodeClient.EventStream` opens the HTTP stream with Req, delegates SSE frame parsing to `ReqServerSentEvents`, then JSON-decodes each frame's `data` payload.

## Boundary between generated and manual code

Generated endpoint and schema modules live under `lib/opencode_client/generated/`. Manual code stays outside that directory: `OpencodeClient.Client` implements the `client.request/1` callback configured via `output.default_client`, and `OpencodeClient.EventStream` handles SSE stream consumption, which OpenAPI generators do not model as ordinary request/response operations.
