# Cloudflare Browser Rendering CLI (bwx)

Retrieve full webpage content via the `bwx` CLI wrapper.

## CLI

- **Command:** `bwx` (wrapper that injects `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` from `pass-cli`)
- **Underlying tool:** `bw` — Cloudflare Browser Rendering CLI

## Usage

`bwx` is a thin wrapper around `bw` that injects credentials via environment variables. All `bw` subcommands and flags are supported.

### Primary: Markdown Extraction

```
bwx markdown --url https://example.com
bwx markdown --url https://example.com --wait-until networkidle0
```

### Other Subcommands

| Subcommand  | Use Case                                |
| ----------- | --------------------------------------- |
| `content`   | Fetch rendered HTML from a URL          |
| `screenshot`| Capture a screenshot of a URL           |
| `pdf`       | Generate a PDF from a URL               |
| `markdown`  | Extract markdown from a URL             |
| `snapshot`  | Capture both HTML and screenshot        |
| `scrape`    | Extract elements by CSS selector        |
| `json`      | Extract structured data using AI        |
| `links`     | Retrieve all links from a URL           |
| `crawl`     | Manage async crawl jobs                 |

## Key Parameters (markdown)

| Parameter       | Description                                                     |
| --------------- | --------------------------------------------------------------- |
| `--url`         | URL to fetch                                                    |
| `--wait-until`  | Page load strategy: `load`, `domcontentloaded`, `networkidle0`, `networkidle2` |
| `--output`, `-o`| Output file path (otherwise prints to stdout)                   |

## Tips

- Only fetch URLs that are likely to contain the needed information
- Prefer fetching official documentation pages over third-party content
- Do not fetch multiple pages when one is sufficient
- Use `--wait-until networkidle0` for JavaScript-heavy pages
