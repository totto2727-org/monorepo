# Workgraph Testing

## Test Layout

Each module owns its tests.

| Module                    | Tests                                                              | Targets    |
| ------------------------- | ------------------------------------------------------------------ | ---------- |
| `workgraph-core`          | Graph compilation, runtime, state, resources, events, identifiers  | native, js |
| `workgraph-agent-cli`     | Coding-agent session scope, lifecycle, errors, cancellation        | native     |
| `workgraph-llm`           | Callback boundary and public `mizchi/llm.MockProvider` integration | native, js |
| `workgraph-visualization` | Deterministic Mermaid rendering                                    | native, js |
| `workgraph-codex-cli`     | Adapter mapping and fake native Codex process integration          | native     |
| `workgraph-opencode-cli`  | Adapter mapping and fake native OpenCode process integration       | native     |

The deleted cross-module E2E workflow and shared testing package are not part of the current suite. Remote provider calls remain manual because normal tests require no credentials.

## Focused Commands

```bash
moon test --target native mbt/package/workgraph-core/src
moon test --target js mbt/package/workgraph-core/src
moon test --target native mbt/package/workgraph-agent-cli/src
moon test --target native mbt/package/workgraph-llm/src
moon test --target js mbt/package/workgraph-llm/src
moon test --target native mbt/package/workgraph-llm/src/test
moon test --target js mbt/package/workgraph-llm/src/test
moon test --target native mbt/package/workgraph-visualization/src
moon test --target js mbt/package/workgraph-visualization/src
moon test --target native mbt/package/workgraph-codex-cli/src
moon test --target native mbt/package/workgraph-codex-cli/src/test
moon test --target native mbt/package/workgraph-opencode-cli/src
moon test --target native mbt/package/workgraph-opencode-cli/src/test
```

## Repository Gate

```bash
vp run mbt:fix
vp run mbt:check
vp run mbt:build
vp run mbt:test
```

Codex and OpenCode integration tests use deterministic fake executables to verify argv, environment, JSONL, continuation, failure, and cancellation behavior. Real CLI examples are separate manual checks and depend on valid local authentication.
