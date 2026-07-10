# bw

Native MoonBit implementation of the `bw` Cloudflare Browser Rendering CLI.

```bash
moon run ./src --target native -- markdown --url https://example.com
moon run ./src --target native -- screenshot --url https://example.com --output page.png
moon run ./src --target native -- markdown --config bw-config.json
```

Every command and crawl subcommand accepts `--config <path>` with a JSON object.
Values are resolved with this precedence:

1. CLI option
2. Config file key
3. Existing default or environment fallback

Credentials use the same order: `--account-id` / `--api-token`, then
`account_id` / `api_token` in the config file, then
`CLOUDFLARE_ACCOUNT_ID` / `CLOUDFLARE_API_TOKEN`.

Config keys use snake_case names matching the option structs. `html` and
`schema` are file paths, the same as their CLI options.

```json
{
  "account_id": "your-account-id",
  "api_token": "your-api-token",
  "url": "https://example.com",
  "wait_until": "networkidle",
  "output": "page.png",
  "full_page": true,
  "width": 1280,
  "height": 720,
  "formats": ["html", "markdown"]
}
```
