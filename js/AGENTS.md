# js

## Required Skills

Before editing JavaScript or TypeScript production code under `js/`, read [`js-coding`](../plugins/totto2727-coding/skills/js-coding/SKILL.md). Before editing JavaScript or TypeScript tests, also read [`js-test`](../plugins/totto2727-coding/skills/js-test/SKILL.md). These language skills route to the required shared principles and focused references; do not substitute a generated documentation skill for them.

## Commands

JavaScript root tasks are Vite+ tasks defined in the repository-root `vite.config.ts`.

```bash
vp run js:check # JavaScript format / lint / type check
vp run js:fix   # JavaScript auto-fix, then type check
vp run js:test  # JavaScript tests
```

## Vite+ Test Commands

Use Vite+ test helpers for file-level JavaScript and TypeScript test runs:

```bash
vp test run <test-file> # Run a specific test file
vp test related <source> # Run tests related to a source file
```
