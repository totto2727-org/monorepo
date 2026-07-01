# bw

Native MoonBit implementation of the `bw` Cloudflare Browser Rendering CLI.

```bash
moon run ./src --target native -- markdown --url https://example.com
moon run ./src --target native -- screenshot --url https://example.com --output page.png
```

Credentials are read from `--account-id` / `--api-token` or `CLOUDFLARE_ACCOUNT_ID` / `CLOUDFLARE_API_TOKEN`.
