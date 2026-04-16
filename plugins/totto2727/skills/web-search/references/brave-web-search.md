# Brave Web Search (brave_web_search)

Search the web with real-time results via the Brave Search MCP server.

## MCP Server

- **Server name:** `plugin:totto2727:brave-search` (or local MCP configuration)
- **Tool name:** `brave_web_search`
- **Package:** `@brave/brave-search-mcp-server`

## Usage

The `brave_web_search` tool accepts a search query and returns results including titles, URLs, and descriptions.

### Example Queries

- "Latest React 19 documentation and new features"
- "Python asyncio best practices 2026"
- "Cloudflare Workers KV API reference"

## Parameters

| Parameter          | Required | Default      | Description                                                     |
| ------------------ | -------- | ------------ | --------------------------------------------------------------- |
| `query`            | Yes      | —            | Search query (max 400 chars, 50 words)                          |
| `country`          | No       | `US`         | Country code for search results                                 |
| `search_lang`      | No       | `en`         | Search language                                                 |
| `ui_lang`          | No       | `en-US`      | UI language                                                     |
| `count`            | No       | `10`         | Number of results (1-20)                                        |
| `offset`           | No       | `0`          | Result offset (max 9)                                           |
| `safesearch`       | No       | `moderate`   | Safe search level: `off`, `moderate`, `strict`                  |
| `freshness`        | No       | —            | Time filter: `pd` (day), `pw` (week), `pm` (month), `py` (year) |
| `text_decorations` | No       | `true`       | Include highlighting markers                                    |
| `spellcheck`       | No       | `true`       | Enable spellcheck                                               |
| `result_filter`    | No       | `web, query` | Filter result types                                             |
| `summary`          | No       | `false`      | Enable AI summarization                                         |
| `extra_snippets`   | No       | `false`      | Additional excerpts (Pro plan only)                             |

## Tips

- Use specific, descriptive queries for better results
- Include version numbers or year when searching for documentation
- Target official sources by including "official docs" or the domain name in the query
- Use `freshness` parameter to filter by time when searching for recent information
- Sensitive information (API keys, passwords, credentials) must not be included in queries
