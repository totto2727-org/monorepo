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
# Generated operation modules call opts[:client].request/1.
# A concrete HTTP client implementation is added separately from generation.
{:ok, session} = OpencodeClient.Generated.Session.session_create(%{
  title: "My Session",
  directory: "/path/to/project"
}, client: MyClient)

# Send prompt asynchronously
{:ok, _} = OpencodeClient.Generated.Session.session_prompt_async(session.id, %{
  parts: [%{type: "text", text: "Hello, implement a feature"}]
}, client: MyClient)

# Delete session
{:ok, _} = OpencodeClient.Generated.Session.session_delete(session.id, client: MyClient)
```

## Modules

- `OpencodeClient.Generated.Session` — generated session operations
- `OpencodeClient.Generated.*` — generated OpenCode schemas and operation groups

## Dependencies

- `req` — HTTP client
- `jason` — JSON encoding/decoding
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

### SSE

SSE support is intentionally not generated in this first stage. Add it after the generated-only commit, using an existing SSE client/parser library if available; write custom SSE parsing only if no suitable library exists.
