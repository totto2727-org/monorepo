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

Configuration is loaded through Admiral's typed JSON config map. Values are resolved with this precedence:

1. CLI option
2. Environment variable
3. Config file key
4. Option default

Environment variables use `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN`, `BW_URL`, `BW_HTML`, `BW_WAIT_UNTIL`, `BW_OUTPUT`, `BW_FULL_PAGE`, `BW_WIDTH`, `BW_HEIGHT`, `BW_LANDSCAPE`, `BW_FORMAT`, `BW_SELECTOR`, `BW_PROMPT`, `BW_SCHEMA`, `BW_CRAWL_ID`, `BW_CRAWL_LIMIT`, `BW_CRAWL_DEPTH`, `BW_CRAWL_FORMATS`, `BW_VISIBLE_ONLY`, and `BW_INTERNAL_ONLY`.

Config keys are independent snake_case names: `account_id`, `api_token`, `url`, `html`, `wait_until`, `output`, `full_page`, `width`, `height`, `landscape`, `format`, `selector`, `prompt`, `schema`, `id`, `limit`, `depth`, `formats`, `visible_only`, and `internal_only`. The loader preserves every JSON property mechanically as `Map[String, Json]`; Admiral selects declared keys and decodes their typed values. `html` and `schema` are file paths, the same as their CLI options.
For multiple crawl formats, use a JSON string array such as `"formats": ["html", "markdown"]` or repeat `--format` on the command line. The `BW_CRAWL_FORMATS` environment variable remains a single scalar value and may use a comma-separated string.

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
