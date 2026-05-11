# Brave Search CLI (bsx)

Search the web with real-time results via the `bx` CLI wrapper.

## CLI

- **Command:** `bsx` (wrapper that injects `BRAVE_SEARCH_API_KEY` from `pass-cli`)
- **Underlying tool:** `bx` — Brave Search CLI
- **API:** Brave Search API (independent web index)

## Usage

`bsx` is a thin wrapper around `bx` that injects the API key via environment variable. All `bx` subcommands and flags are supported.

### Primary: RAG Grounding

`bsx context "query"` is the recommended endpoint for AI agents — returns pre-extracted, token-budgeted web content:

```
bsx context "Python TypeError cannot unpack non-iterable NoneType" --max-tokens 4096
bsx context "tokio vs async-std Rust async runtime" --count 5 --threshold strict
bsx context "how to implement retry with exponential backoff" --max-tokens 2048
bsx context "axum middleware" --include-site docs.rs --max-tokens 4096
```

### Web Search

For raw search results with full metadata:

```
bsx web "site:docs.rs reqwest" | jq .
bsx web "React 19 new features" --count 20
```

### Other Subcommands

`bsx answers`, `bsx news`, `bsx images`, `bsx videos`, `bsx places`, `bsx suggest`, `bsx spellcheck`

## Key Parameters

| Parameter          | Description                                            |
| ------------------ | ------------------------------------------------------ |
| `--count`          | Number of results (context: 1-20, web: 1-20)           |
| `--max-tokens`     | Token budget for RAG grounding output                  |
| `--threshold`      | Relevance threshold: `strict`, `balanced`, `lenient`   |
| `--country`        | Country code for search results                        |
| `--freshness`      | Time filter: query with date qualifiers                |
| `--include-site`   | Restrict to specific domains                           |
| `--exclude-site`   | Exclude specific domains                               |
| `--goggles`        | Custom ranking (boost docs, discard spam)              |

## Tips

- Use specific, descriptive queries for better results
- Include version numbers or year when searching for documentation
- Target official sources by including "official docs" or the domain name in the query
- Prefer `bsx context` over `bsx web` for AI agent use — it returns clean, token-budgeted content
- Sensitive information (API keys, passwords, credentials) must not be included in queries
