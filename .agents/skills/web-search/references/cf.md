# Cloudflare CLI (`cf`)

Retrieve full webpage content through Cloudflare Browser Rendering with the `cf` CLI.

## CLI

- **Command:** `cf browser-rendering` — Cloudflare Browser Rendering API commands
- **Required env:** `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`

## Usage

### Primary: Markdown Extraction

```
body="$(jq -cn --arg url "$URL" '{url: $url}')"
cf browser-rendering markdown create --body "$body"

body="$(jq -cn --arg url "$URL" '{url: $url, gotoOptions: {waitUntil: "networkidle0"}}')"
cf browser-rendering markdown create --body "$body"
```

### Other Commands

| Command             | Use Case                         |
| ------------------- | -------------------------------- |
| `content create`    | Fetch rendered HTML from a URL   |
| `screenshot create` | Capture a screenshot of a URL    |
| `pdf create`        | Generate a PDF from a URL        |
| `markdown create`   | Extract markdown from a URL      |
| `snapshot create`   | Capture both HTML and screenshot |
| `scrape create`     | Extract elements by CSS selector |
| `json create`       | Extract structured data using AI |
| `links create`      | Retrieve all links from a URL    |
| `crawl create`      | Start an async crawl job         |

## Tips

- Pass the API request body through `--body` as JSON.
- Serialize externally supplied URLs with `jq --arg`; do not interpolate them into shell-quoted JSON.
- Use `gotoOptions.waitUntil` with `networkidle0` for JavaScript-heavy pages.
- Only fetch URLs that are likely to contain the needed information.
- Prefer fetching official documentation pages over third-party content.
- Do not fetch multiple pages when one is sufficient.
