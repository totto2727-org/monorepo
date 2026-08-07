# workgraph-codex-cli

`workgraph-codex-cli` implements the `workgraph-core` coding-agent contract with the native Codex CLI SDK.

## Package

```moonbit
import {
  "totto2727/workgraph-codex-cli"
}
```

The module supports and prefers the native target.

## Example

The example uses the local Codex CLI authentication and runs a read-only prompt in the current workspace.

```bash
moon run --target native mbt/package/workgraph-codex-cli/src/examples/basic
```
