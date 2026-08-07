# workgraph-opencode-cli

`workgraph-opencode-cli` implements the `workgraph-core` coding-agent contract with the native OpenCode CLI SDK.

## Package

```moonbit
import {
  "totto2727/workgraph-opencode-cli"
}
```

The module supports and prefers the native target.

## Example

The example uses the local OpenCode CLI configuration and runs a read-only prompt in the current workspace.

```bash
moon run --target native mbt/package/workgraph-opencode-cli/src/examples/basic
```
