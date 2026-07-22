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

Config keys are the environment-variable names declared by the CLI options. Values are converted mechanically to Admiral's `Map[String, String]`: strings are preserved, arrays are ignored because argparse does not accept array-valued environment input, and other JSON values use their compact JSON representation. Unknown keys are preserved without application-specific handling. `BW_HTML` and `BW_SCHEMA` are file paths, the same as their CLI options.
For multiple crawl formats, use a comma-separated scalar string such as `"BW_CRAWL_FORMATS": "html,markdown"` or repeat `--format` on the command line.

`json` prints the Cloudflare JSON response by default. Use `--format markdown` or `--format text` to print the extracted `result` as unstyled plain text for redirection.

```json
{
  "CLOUDFLARE_ACCOUNT_ID": "your-account-id",
  "CLOUDFLARE_API_TOKEN": "your-api-token",
  "BW_URL": "https://example.com",
  "BW_WAIT_UNTIL": "networkidle",
  "BW_OUTPUT": "page.png",
  "BW_FULL_PAGE": true,
  "BW_WIDTH": 1280,
  "BW_HEIGHT": 720,
  "BW_FORMAT": "markdown",
  "BW_CRAWL_FORMATS": "html,markdown"
}
```
