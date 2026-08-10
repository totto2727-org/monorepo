# Brave Search CLI (bx)

Search the web with real-time results via the `bx` CLI.

## CLI

- **Command:** `bx` — Brave Search CLI
- **API:** Brave Search API (independent web index)
- **Required env:** `BRAVE_SEARCH_API_KEY`

## Usage

### Primary: RAG Grounding

`bx context "query"` is the recommended endpoint for AI agents — returns pre-extracted, token-budgeted web content:

```
bx context "Python TypeError cannot unpack non-iterable NoneType" --max-tokens 4096
bx context "tokio vs async-std Rust async runtime" --count 5 --threshold strict
bx context "how to implement retry with exponential backoff" --max-tokens 2048
bx context "axum middleware" --include-site docs.rs --max-tokens 4096
```

### Web Search

For raw search results with full metadata:

```
bx web "site:docs.rs reqwest" | jq .
bx web "React 19 new features" --count 20
```

### Other Subcommands

`bx answers`, `bx news`, `bx images`, `bx videos`, `bx places`, `bx suggest`, `bx spellcheck`

## Key Parameters

| Parameter        | Description                                          |
| ---------------- | ---------------------------------------------------- |
| `--count`        | Number of results (context: 1-20, web: 1-20)         |
| `--max-tokens`   | Token budget for RAG grounding output                |
| `--threshold`    | Relevance threshold: `strict`, `balanced`, `lenient` |
| `--country`      | Country code for search results                      |
| `--freshness`    | Time filter: query with date qualifiers              |
| `--include-site` | Restrict to specific domains                         |
| `--exclude-site` | Exclude specific domains                             |
| `--goggles`      | Custom ranking (boost docs, discard spam)            |

## Tips

- Use specific, descriptive queries for better results
- Include version numbers or year when searching for documentation
- Target official sources by including "official docs" or the domain name in the query
- Prefer `bx context` over `bx web` for AI agent use — it returns clean, token-budgeted content
- Sensitive information (API keys, passwords, credentials) must not be included in queries
