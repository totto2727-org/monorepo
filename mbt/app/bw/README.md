# bw

Native MoonBit implementation of the `bw` Cloudflare Browser Rendering CLI.

```bash
moon run ./src --target native -- markdown --url https://example.com
moon run ./src --target native -- json --url https://example.com --prompt "Extract the title"
moon run ./src --target native -- json --url https://example.com --prompt "Extract the title" --format markdown > result.md
moon run ./src --target native -- json --url https://example.com --prompt "Extract the title" --format text > result.txt
moon run ./src --target native -- screenshot --url https://example.com --output page.png
```

`json` prints the Cloudflare JSON response by default. Use `--format markdown` or `--format text` to print the extracted `result` as unstyled plain text for redirection.

Credentials are read from `--account-id` / `--api-token` or `CLOUDFLARE_ACCOUNT_ID` / `CLOUDFLARE_API_TOKEN`.
