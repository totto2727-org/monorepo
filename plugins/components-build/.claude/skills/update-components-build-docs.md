---
name: update-components-build-docs
description: Use when updating components.build documentation links, refreshing the components-build-docs skill, or when the user asks to sync components.build docs.
---

# Update components.build Docs Skill

## Overview

Fetches the latest sitemap from components.build and regenerates the SKILL.md link index in `skills/components-build-docs/`.

## Steps

1. **Run the generator script**:

```bash
deno run --allow-net --allow-read --allow-write .script/generate-skill.ts
```

2. **Verify output** — Confirm `skills/components-build-docs/SKILL.md` was generated with the expected number of links.
