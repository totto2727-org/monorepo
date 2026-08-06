# Workgraphのテスト

## テスト配置

各モジュールが自身のテストを所有します。

| モジュール                | テスト                                                        | Targets    |
| ------------------------- | ------------------------------------------------------------- | ---------- |
| `workgraph-core`          | グラフコンパイル、runtime、state、resource、event、identifier | native, js |
| `workgraph-agent-cli`     | coding-agent session scope、lifecycle、error、cancellation    | native     |
| `workgraph-llm`           | callback境界と公開`mizchi/llm.MockProvider` integration       | native, js |
| `workgraph-visualization` | 決定的なMermaid rendering                                     | native, js |
| `workgraph-codex-cli`     | adapter mappingとfake native Codex process integration        | native     |
| `workgraph-opencode-cli`  | adapter mappingとfake native OpenCode process integration     | native     |

削除したモジュール横断E2E workflowと共有testingパッケージは、現在のsuiteに含まれません。通常テストは認証情報を必要としないため、remote provider呼び出しはmanual checkとして残します。

## 個別コマンド

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

## リポジトリgate

```bash
vp run mbt:fix
vp run mbt:check
vp run mbt:build
vp run mbt:test
```

CodexとOpenCodeのintegration testは決定的なfake executableを使用し、argv、environment、JSONL、continuation、failure、cancellationを検証します。実CLI exampleは別のmanual checkであり、有効なローカル認証に依存します。
