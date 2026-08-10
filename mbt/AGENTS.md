# mbt

## Required Skills

Before editing MoonBit production code under `mbt/`, read [`mbt-coding`](https://github.com/totto2727-org/agent/blob/main/plugins/totto2727-coding/skills/mbt-coding/SKILL.md). Before editing MoonBit tests, also read [`mbt-test`](https://github.com/totto2727-org/agent/blob/main/plugins/totto2727-coding/skills/mbt-test/SKILL.md). These language skills are maintained in the external `totto2727-org/agent` plugin repository and route to the required shared principles and focused references; do not substitute the generated `docs-moonbit` skill for them.

## Commands

MoonBit uses the repository-root `moon.work`. Root MoonBit tasks are Vite+ tasks defined in the repository-root `vite.config.ts`.

```bash
vp run mbt:build # moon build
vp run mbt:check # moon check
vp run mbt:fix   # moon fmt
vp run mbt:test  # moon test
```

MoonBit packages do not define project-level Vite+ tasks. Use `moon` directly only when a command must target a specific package or has no root task:

```bash
moon info mbt/package/admiral
moon test mbt/package/codex-sdk/src
moon test --update
moon coverage analyze > uncovered.log
```

## README Files

Use `README.mbt.md` as the source README for every MoonBit project, and keep `README.md` as a relative symbolic link to `README.mbt.md`.
