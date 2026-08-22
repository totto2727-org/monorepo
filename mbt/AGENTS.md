# mbt

## Required Skills

Before editing MoonBit production code under `mbt/`, read [`mbt-coding`](https://github.com/totto2727-org/agent/blob/main/plugins/totto2727-coding/skills/mbt-coding/SKILL.md). Before editing MoonBit tests, also read [`mbt-test`](https://github.com/totto2727-org/agent/blob/main/plugins/totto2727-coding/skills/mbt-test/SKILL.md). Use the official `$moonbit-orientation` skill locally when it is installed for language and toolchain source routing; otherwise fetch the [official MoonBit documentation](https://docs.moonbitlang.com/en/latest/) directly and request `Accept: text/markdown` when the client supports content negotiation. Keep `mbt-coding` and `mbt-test` authoritative for repository production and test practices.

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
moon test --update
moon coverage analyze > uncovered.log
```

## README Files

Use `README.mbt.md` as the source README for every MoonBit project, and keep `README.md` as a relative symbolic link to `README.mbt.md`.
