# workgraph-agent-cli

`workgraph-agent-cli` provides native coding-agent contracts, graph nodes, and session resource management for `workgraph-core`. The core package remains provider-neutral and exposes only node patches and optional values; coding-agent status, policies, sessions, requests, responses, and identifiers are owned here.

The package intentionally has no standalone example. Use the runnable `workgraph-codex-cli` and `workgraph-opencode-cli` examples to see this node with concrete coding-agent implementations.

## Package

```moonbit
import {
  "totto2727/workgraph-agent-cli"
}
```

The module supports the native target and prefers native builds.
