# bw

Native MoonBit implementation of the `bw` Cloudflare Browser Rendering CLI.

```bash
moon run ./src --target native -- markdown --url https://example.com
moon run ./src --target native -- json --url https://example.com --prompt "Extract the title"
moon run ./src --target native -- json --url https://example.com --prompt "Extract the title" --format markdown > result.md
moon run ./src --target native -- json --url https://example.com --prompt "Extract the title" --format text > result.txt
moon run ./src --target native -- screenshot --url https://example.com --output page.png
moon run ./src --target native -- markdown --config bw-config.json
moon run ./src --target native -- --config bw-config.json crawl start --format html --format markdown
```

`--config <path>` is a global option and may appear before or after a command at any nesting depth. When it is omitted, `bw` loads `bw-config.json` from the current directory if that file exists. A missing default file is ignored, while a missing explicitly selected file is an error.

Configuration is loaded through Admiral's environment-backed config map. Values are resolved with this precedence:

1. CLI option
2. Environment variable
3. Config file key
4. Option default

Credentials use `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_API_TOKEN`. Other config-backed options use `BW_URL`, `BW_HTML`, `BW_WAIT_UNTIL`, `BW_OUTPUT`, `BW_FULL_PAGE`, `BW_WIDTH`, `BW_HEIGHT`, `BW_LANDSCAPE`, `BW_FORMAT`, `BW_SELECTOR`, `BW_PROMPT`, `BW_SCHEMA`, `BW_CRAWL_ID`, `BW_CRAWL_LIMIT`, `BW_CRAWL_DEPTH`, `BW_CRAWL_FORMATS`, `BW_VISIBLE_ONLY`, and `BW_INTERNAL_ONLY`.

Config keys use snake_case names matching the CLI options. `html` and `schema` are file paths, the same as their CLI options.
The `formats` config array is normalized through the same plural option path as repeated `--format` values; comma-separated values remain supported.

`json` prints the Cloudflare JSON response by default. Use `--format markdown` or `--format text` to print the extracted `result` as unstyled plain text for redirection.

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
  "format": "markdown",
  "formats": ["html", "markdown"]
}
```
