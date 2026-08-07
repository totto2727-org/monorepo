# Workgraph Package Split Record

## Outcome

The former monolithic graph module is split into six independently targeted MoonBit modules. Runtime-independent code no longer inherits native-only CLI dependencies.

## Package Boundaries

```text
mbt/package/
├── workgraph-core/
│   └── src/examples/basic/
├── workgraph-agent-cli/
├── workgraph-llm/
│   ├── src/examples/basic/
│   └── src/test/
├── workgraph-visualization/
│   └── src/examples/basic/
├── workgraph-codex-cli/
│   ├── src/examples/basic/
│   └── src/test/
└── workgraph-opencode-cli/
    ├── src/examples/basic/
    └── src/test/
```

Core owns identifiers, graph construction and compilation, runtime state reduction, events, coding-agent contracts, and the in-memory resource store. It does not import LLM or CLI SDKs.

`workgraph-agent-cli`, `workgraph-llm`, and `workgraph-visualization` each import core. Codex and OpenCode import core and agent CLI plus only their corresponding CLI SDK.

## Target Policy

- `workgraph-core`, `workgraph-llm`, and `workgraph-visualization` have no preferred target and support native and JavaScript.
- `workgraph-agent-cli`, `workgraph-codex-cli`, and `workgraph-opencode-cli` prefer and support native.

## Test Ownership

Unit tests remain beside their implementation files. LLM provider, Codex CLI, and OpenCode CLI integration tests live under the owning module's `src/test` package. The former shared testing helpers and cross-module E2E workflow were removed because they existed only for the deleted aggregate workflow suite.

## Examples

- Core provides the basic graph and in-memory resource example.
- LLM provides a credential-free `mizchi/llm.MockProvider` graph example.
- Visualization provides the Mermaid example.
- Codex and OpenCode each provide a real CLI-backed coding-agent graph example.
- Coding has no standalone example because both CLI modules exercise it.

## Verification

```bash
vp run mbt:check
vp run mbt:build
vp run mbt:test
moon run --target native mbt/package/workgraph-llm/src/examples/basic
moon run --target js mbt/package/workgraph-llm/src/examples/basic
moon run --target native mbt/package/workgraph-codex-cli/src/examples/basic
moon run --target native mbt/package/workgraph-opencode-cli/src/examples/basic
```
