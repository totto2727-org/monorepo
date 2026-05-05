---
name: update-docs-components-build
description: Use when updating components.build documentation links, refreshing the docs-components-build skill, or when the user asks to sync components.build docs.
---

# Update components.build Docs Skill

## Overview

Fetches the latest sitemap from components.build and regenerates the SKILL.md link index in `skills/docs-components-build/`.

## Steps

1. **Run the generator script**:

```bash
deno run --allow-net --allow-read --allow-write .script/generate-docs-components-build.ts
```

2. **Verify output** — Confirm `skills/docs-components-build/SKILL.md` was generated with the expected number of links.
