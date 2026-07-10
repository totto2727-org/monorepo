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

## Immutable Collection Review

MoonBit collection refactor rules live in
`plugins/totto2727-coding/skills/coding/references/mbt/bestpractice.md`.
Apply that guidance when writing or reviewing `.mbt` code.

For immutable refactor reviews, start with this structural scan:

```bash
rg -n '\bmut\b|\bfor\b|\.push\(|\[[^]]+\]\s*=' mbt --glob '*.mbt'
```

Classify every remaining hit instead of blindly removing all mutation or loops:

- simple collection transformation that should become `map`, `filter`,
  `filter_map`, `fold`, `flat_map`, `concat`, or `collect`
- effectful traversal where `for` remains clearer because each iteration
  performs I/O, Git, printing, symlink, network, or other async/effectful work
- algorithmic state machine where local `mut` is intrinsic to clarity
- unavoidable mutable library object construction
- test-only imperative setup

Generated `docs-moonbit` skill files are upstream language references. Do not
hand-edit them for repository coding rules; update the `coding` skill reference
instead.
