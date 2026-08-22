# Rust Application Libraries

Use these libraries as defaults for the matching capability, then verify the current release, maintenance state, Rust version, and exact API before implementation. A recommendation is not permission to add an unused dependency.

## Selection table

| Capability                                     | Preferred library     | Boundary                                                                      |
| ---------------------------------------------- | --------------------- | ----------------------------------------------------------------------------- |
| Server-driven Rust web UI                      | Topcoat with Datastar | Rust owns routing and HTML; Datastar owns browser actions and partial patches |
| LLM completions, agents, tools, and embeddings | Rig                   | Keep provider-specific types behind an application boundary                   |
| Code-defined graph workflow execution          | graph-flow            | Keep workflow definitions separate from runtime sessions and UI history       |
| Wire-format parsing and serialization          | Serde data formats    | Deserialize external syntax directly into typed wire models                   |
| Semantic and business validation               | garde                 | Validate values only after successful deserialization                         |
| Structured application and HTTP logging        | `tracing`             | Emit operational metadata without sensitive payloads                          |

## LLM applications with Rig

Use Rig as the first choice when a Rust application needs LLM completions, agents, tools, embeddings, or provider integrations. Depend on the smallest Rig crate or feature set that provides the required abstraction.

Keep provider clients and provider-specific request types behind an application service. Let domain and workflow code depend on application commands and results rather than OpenAI-, Anthropic-, or model-specific structures.

Treat LLM token streaming and workflow execution progress as distinct timelines unless they patch the same coherent UI boundary. Convert provider events into typed application events before exposing them to workflow or web layers.

Do not log prompts, tool arguments, retrieved documents, or model responses by default. Record identifiers, model name, timing, token counts, and failure categories when those fields are safe and operationally useful.

Rig changes quickly and explicitly warns about breaking changes. Check release notes and migration guidance before upgrades, keep the lockfile in applications, and isolate provider behavior so upgrades remain local.

## Workflows with graph-flow

Use graph-flow as the preferred workflow engine for code-defined graphs, tasks, conditional edges, sessions, and observable execution status.

Keep each workflow in its own module or directory. Let that module own its stable workflow ID, form, typed and validated input, graph construction, topology description, defaults, schedules, and display metadata. Let the application registry enumerate definitions and select a runtime by workflow ID.

Keep immutable graph definitions separate from per-run session state and execution history. Use globally unique run or session IDs when multiple graph runners share storage or application history.

Choose step-by-step execution when the application must expose the active node, selected edge, timing, state, and output after every task. Continuous execution is appropriate only when intermediate observability and caller control are unnecessary.

Keep a serializable topology descriptor beside the executable graph when the UI must enumerate nodes and edges and the engine does not expose the required introspection. Do not infer a UI route from callbacks or private engine state.

Wrap graph-flow at the application boundary before forking it. Modify or fork only when a confirmed API gap cannot be represented by an adapter or parallel metadata.

## Serde, garde, then domain construction

Apply input handling in this order:

```text
request bytes or text
  -> format-specific Serde deserializer
  -> typed wire DTO
  -> garde Validate
  -> TryFrom or domain constructor
  -> normalized domain command
  -> application or workflow execution
```

Use the data-format parser with Serde support: `serde_json` for JSON, `toml` for TOML, and `csv` record deserialization for CSV. Deserialize directly into a typed wire DTO when the input shape is known instead of keeping `serde_json::Value`, TOML values, string records, or maps in application code.

Use Serde for structural decoding: object shape, field names, required fields, enums, numbers, strings, and unknown-field policy. Prefer `#[serde(deny_unknown_fields)]` for closed request objects so a form from one workflow cannot silently become valid input for another workflow.

Use garde after deserialization for semantic rules such as non-blank text, length, numeric ranges, formats, nested values, cross-field relationships, and custom business policies. Keep parse errors and validation reports as different boundary error categories.

After validation, convert the DTO through `TryFrom` or an explicit domain constructor so internal code receives a type whose invariants hold. Keep domain-construction failures distinct from parser and garde failures.

Normalize only when the normalization is part of the accepted input contract. If validation applies to trimmed text, normalize before or during validation and construct the domain value from that same representation; do not validate one representation and execute another without documenting the order.

Keep workflow-specific DTOs and validators inside the workflow module. A generic web action should forward the selected workflow ID and raw input object to the workflow registry rather than know every workflow's fields.

## Logging with tracing

Initialize `tracing` once at the executable boundary. At minimum, record the loopback listening URL and one completed-request event containing method, normalized route template or redacted path, status code, and elapsed time. Omit query strings by default and allowlist only query fields known to be safe.

Add workflow and LLM logs only after choosing their consumers and redaction policy. Prefer structured fields over interpolated messages, and never record secrets or full payloads merely because they are available.

## Dependency versions

Prefer normal Cargo compatible version requirements for libraries unless exact source reproducibility or an upstream fix requires a tighter constraint. Avoid `=version` by default; let `Cargo.lock` pin application builds and use CI plus upgrade review to control movement.

For fast-moving or experimental libraries, verify the selected release and public API before coding. If a Git dependency is temporarily required, pin a commit and document why the crates.io release is insufficient; return to a registry release when the gap closes.

## Official sources

- [Rig repository and feature overview](https://github.com/0xPlaygrounds/rig)
- [Rig documentation](https://rig.rs/docs)
- [graph-flow repository](https://github.com/a-agmon/rs-graph-llm)
- [graph-flow 0.6 graph builder source](https://github.com/a-agmon/rs-graph-llm/blob/f18bf6a197fda9ee47f2ad21a625e985740e0cbb/graph-flow/src/graph.rs#L226-L383)
- [graph-flow 0.6 runner source](https://github.com/a-agmon/rs-graph-llm/blob/f18bf6a197fda9ee47f2ad21a625e985740e0cbb/graph-flow/src/runner.rs#L216-L259)
- [Serde data model](https://serde.rs/data-model.html)
- [Implementing a Serde deserializer](https://serde.rs/impl-deserializer.html)
- [`serde_json` typed deserialization](https://docs.rs/serde_json/latest/serde_json/fn.from_slice.html)
- [`toml` typed deserialization](https://docs.rs/toml/latest/toml/fn.from_str.html)
- [`csv` Serde deserialization](https://docs.rs/csv/latest/csv/struct.Reader.html#method.deserialize)
- [garde validation](https://docs.rs/garde/0.23.0/garde/)
- [tracing documentation](https://docs.rs/tracing/latest/tracing/)
