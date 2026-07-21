# mbt

## Required Skills

Before editing MoonBit production code under `mbt/`, read [`mbt-coding`](../plugins/totto2727-coding/skills/mbt-coding/SKILL.md). Before editing MoonBit tests, also read [`mbt-test`](../plugins/totto2727-coding/skills/mbt-test/SKILL.md). These language skills route to the required shared principles and focused references; do not substitute the generated `docs-moonbit` skill for them.

## Commands

MoonBit uses the repository-root `moon.work`. Root MoonBit tasks are Vite+ tasks defined in the repository-root `vite.config.ts`.

```bash
vp run mbt:check # moon check
vp run mbt:fix   # moon fmt
vp run mbt:test  # moon test
```

Build remains a project-level task and is collected by `vp run w:build`.

## Moon Commands

Use `moon` directly for MoonBit subcommands that are not Vite+ tasks:

```bash
moon info          # Update generated interface files (.mbti)
moon test --update # Update snapshot tests
moon coverage analyze > uncovered.log
```

