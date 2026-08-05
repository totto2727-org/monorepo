# mbt

## Required Skills

Before editing MoonBit production code under `mbt/`, read [`mbt-coding`](../plugins/totto2727-coding/skills/mbt-coding/SKILL.md). Before editing MoonBit tests, also read [`mbt-test`](../plugins/totto2727-coding/skills/mbt-test/SKILL.md). These language skills route to the required shared principles and focused references; do not substitute the generated `docs-moonbit` skill for them.

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

## Visibility and Construction

- Declare structs as `pub` by default and expose canonical `TypeName::TypeName` constructors. Use `pub(all)` only when direct external literals are an intentional API requirement, and document that requirement next to the declaration.
- An enum or suberror that only wraps primitive values or structs without validation, normalization, or cross-field rules may use `pub(all)` and direct `TypeName::VariantName` construction.
- Declare an enum or suberror as `pub` when valid construction follows any rule. Expose the allowed construction paths as type-associated functions with snake_case names, and do not add package-level wrapper functions that merely rename variant construction.
- Use `extenum` only when an existing open union must be extended and an ordinary enum, trait, or closed wrapper cannot express the required integration.
- Declare traits as `pub` by default. Use `pub(open)` only when downstream packages must provide implementations, and document that requirement next to the trait.
- Do not widen type or trait visibility for test convenience. Use the production constructor or factory, or move implementation-detail tests to white-box scope.
