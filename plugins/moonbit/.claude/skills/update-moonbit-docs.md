---
name: update-moonbit-docs
description: Use when updating MoonBit language documentation skills, refreshing moonbit-docs skill files, or when the user asks to sync MoonBit docs.
---

# Update MoonBit Docs Skills

## Overview

Fetches the latest MoonBit language documentation and regenerates skill files in `skills/moonbit-docs/`.

## Steps

1. **Fetch download links** — Use WebFetch on each page below and extract the `Download this section in Markdown` link href:
   - `https://docs.moonbitlang.com/en/latest/language/index.html`
   - `https://docs.moonbitlang.com/en/latest/toolchain/index.html`

2. **Resolve URLs** — Each href is a relative path like `../_downloads/<hash>/summary.md`. Resolve to `https://docs.moonbitlang.com/en/latest/_downloads/<hash>/summary.md`.

3. **Run the generator script**:

```bash
deno run --allow-net --allow-read --allow-write .script/process-moonbit-docs.ts "<language-url>" "<toolchain-url>"
```

4. **Verify output** — Confirm files were generated in `skills/moonbit-docs/`.
