# workgraph-llm

`workgraph-llm` adapts `mizchi/llm` messages, tools, and collected results to `workgraph-core` nodes without selecting a provider or runtime.

## Package

```moonbit
import {
  "totto2727/workgraph-llm"
}
```

The module supports native and JavaScript targets and has no preferred target.

## Example

```bash
moon run --target native mbt/package/workgraph-llm/src/examples/basic
moon run --target js mbt/package/workgraph-llm/src/examples/basic
```
