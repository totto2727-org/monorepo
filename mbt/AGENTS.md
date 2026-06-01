# mbt

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
