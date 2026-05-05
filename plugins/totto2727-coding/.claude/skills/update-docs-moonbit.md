---
name: update-docs-moonbit
description: Use when updating MoonBit language documentation skills, refreshing docs-moonbit skill files, or when the user asks to sync MoonBit docs.
---

# Update MoonBit Docs Skills

## Overview

Fetches the latest MoonBit language documentation and regenerates skill files in `skills/docs-moonbit/`.

## Steps

1. **Fetch download links** — Use WebFetch on each page below and extract the `Download this section in Markdown` link href:
   - `https://docs.moonbitlang.com/en/latest/language/index.html`
   - `https://docs.moonbitlang.com/en/latest/toolchain/index.html`

2. **Resolve URLs** — Each href is a relative path like `../_downloads/<hash>/summary.md`. Resolve to `https://docs.moonbitlang.com/en/latest/_downloads/<hash>/summary.md`.

3. **Run the generator script**:

```bash
deno run --allow-net --allow-read --allow-write .script/generate-docs-moonbit.ts "<language-url>" "<toolchain-url>"
```

4. **Verify output** — Confirm `SKILL.md` was generated in `skills/docs-moonbit/` and reference `.md` files were generated in `skills/docs-moonbit/references/`.
