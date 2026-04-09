---
confirmed: true
---

# ADR: bw — CLI for Cloudflare Browser Rendering REST API

## Context

Cloudflare Browser Rendering REST API provides endpoints for common browser actions (screenshots, HTML capture, PDF generation, web scraping, crawling, etc.) without requiring code deployment. Currently, interacting with this API requires manual curl/HTTP calls with complex JSON payloads.

A dedicated CLI tool (`bw`) wraps the API into ergonomic subcommands, following the same architecture as `c-plugin`.

## Decision

### 1. Project Setup

- Path: `js/app/bw`
- Node.js project (npm publishable, package name: `bw`)
- Build: vite-plus (`vp pack`)

### 2. Tech Stack

| Concern         | Choice                   | Rationale                              |
| --------------- | ------------------------ | -------------------------------------- |
| CLI framework   | `effect/unstable/cli`    | Same as c-plugin, bundled in Effect v4 |
| HTTP client     | `effect/unstable/http`   | Provided by `NodeServices.layer`       |
| Runtime         | `@effect/platform-node`  | Standard Effect Node.js platform layer |
| Schema          | `effect` (Schema)        | Aligns with existing monorepo patterns |
| Terminal output | `Effect.log` / `Console` | No extra dependency needed             |

### 3. Authentication

Secrets are resolved from environment variables with optional CLI flag overrides:

| Source     | Variable / Flag                          |
| ---------- | ---------------------------------------- |
| Account ID | `CLOUDFLARE_ACCOUNT_ID` / `--account-id` |
| API Token  | `CLOUDFLARE_API_TOKEN` / `--api-token`   |

Resolution order: CLI flag > environment variable > error.

### 4. Subcommand Structure

```
bw content       Fetch rendered HTML
bw screenshot    Capture screenshot (PNG)
bw pdf           Generate PDF
bw markdown      Extract markdown
bw snapshot      Capture HTML + screenshot
bw scrape        Extract elements by CSS selector
bw json          AI-powered structured data extraction
bw links         Retrieve all links
bw crawl start   Start async crawl job
bw crawl status  Check crawl job status
bw crawl results Retrieve crawl results
bw crawl list    List all crawl jobs
```

### 5. Common Flags

**Global flags** (all commands):

- `--account-id` — Cloudflare account ID
- `--api-token` — Cloudflare API token

**Input flags** (all POST-based commands):

- `--url` — Target URL
- `--html` — Path to local HTML file (alternative to `--url`)
- `--wait-until` — Page load strategy (`load`, `domcontentloaded`, `networkidle0`, `networkidle2`)
- `--config` — Path to JSON config file for complex options (cookies, headers, viewport, etc.)

**Output flags**:

- `-o, --output` — Output file path (required for `screenshot`, `pdf`, `snapshot`; optional for others)

### 6. Config File

Complex request parameters (cookies, headers, viewport, authentication, script injection, etc.) are specified via a JSON config file passed with `--config`. CLI flags take precedence over config file values.

```json
{
  "cookies": [{ "name": "session", "value": "abc123", "domain": ".example.com" }],
  "headers": { "Authorization": "Bearer mytoken" },
  "viewport": { "width": 1920, "height": 1080 },
  "userAgent": "CustomBot/1.0",
  "authenticate": { "username": "user", "password": "pass" }
}
```

### 7. Project Directory Structure

```
js/app/bw/
  package.json
  tsconfig.json
  vite.config.ts
  src/
    bin.ts
    cli/
      content.ts
      screenshot.ts
      pdf.ts
      markdown.ts
      snapshot.ts
      scrape.ts
      json.ts
      links.ts
      crawl/
        start.ts
        status.ts
        results.ts
        list.ts
    schema/
      common.ts
      config-file.ts
    service/
      auth.ts
      api-client.ts
      output.ts
    lib/
      flags.ts
```

### 8. Crawl Workflow

The `/crawl` endpoint is asynchronous:

1. POST to start — returns job ID
2. GET to poll status / retrieve results

`bw crawl start` supports a `--wait` flag that polls every 3 seconds using `Effect.schedule` with `Schedule.spaced`, logging status updates via `Effect.log`. On completion, results are optionally saved to `-o` file.

### 9. Binary Output Handling

`screenshot` and `pdf` commands require `-o` flag. Response bodies are read as `Uint8Array` and written to the specified file path. `snapshot` writes two files (`{name}.html` and `{name}.png`) to the specified directory.

### 10. Error Handling

Using Effect `Data.TaggedError`:

- `AuthError` — Missing or invalid credentials
- `ApiError` — HTTP errors from Cloudflare API
- `OutputError` — File write failures
- `ConfigFileError` — Invalid `--config` JSON file
- `InputError` — Missing required input (`--url` or `--html`)

## Impact

- **New package**: `js/app/bw/`
- **npm**: Published as `bw` package
- **No changes to existing packages**
