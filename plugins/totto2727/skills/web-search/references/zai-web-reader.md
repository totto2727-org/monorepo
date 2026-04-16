# Z AI Web Reader (webReader)

Retrieve full webpage content via the Z AI MCP server.

## MCP Server

- **Server name:** `plugin:totto2727:web-reader` (or local MCP configuration)
- **Tool name:** `webReader`
- **Endpoint:** `https://api.z.ai/api/mcp/web_reader/mcp`

## Usage

The `webReader` tool accepts a URL and returns the page content including title, main content, metadata, and links.

### Example Usage

Use after `web_search_prime` to fetch detailed content from a promising URL:

1. Search with `web_search_prime` to find relevant pages
2. Pick the most relevant URL from results
3. Fetch full content with `webReader`

### Result Fields

Each result includes:

- **Title** — Page title
- **Main content** — Extracted page body content
- **Metadata** — Page metadata
- **Links** — List of links found on the page

## Tips

- Only fetch URLs that are likely to contain the needed information
- Prefer fetching official documentation pages over third-party content
- Do not fetch multiple pages when one is sufficient

## Quota Limits

Usage is subject to the Z AI plan quota (shared with `web_search_prime`). If quota is exhausted, inform the user and suggest they check their Z AI plan.
