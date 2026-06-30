---
confirmed: true
---

# ADR: vp run scripts use `$(find ...)` instead of shell globs

## Context

When adding the `nix/` workspace package (`@app/nix`) with `check` / `fix` scripts that invoke `nixfmt` over all `*.nix` files, the natural form is:

```json
{
  "scripts": {
    "check": "nixfmt --check **/*.nix",
    "fix": "nixfmt **/*.nix"
  }
}
```

This works under `bun run`, but **fails under `vp run`** with:

```
nixfmt: **/*.nix: openFile: does not exist (No such file or directory)
```

Empirical verification (running `echo args: <pattern>` as a script under both runners against `nix/`):

| Pattern       | `vp run` (vite-plus shell emulator)    | `bun run` (system shell)                     |
| ------------- | -------------------------------------- | -------------------------------------------- |
| `*.nix`       | literal `*.nix`                        | literal `*.nix` (no match at top level)      |
| `*/*.nix`     | literal `*/*.nix` (**unexpanded**)     | 33 files expanded                            |
| `**/*.nix`    | literal `**/*.nix` (**unexpanded**)    | 33 files expanded (bash 3.2 has no globstar) |
| `share/*.nix` | literal `share/*.nix` (**unexpanded**) | 25 files expanded                            |

Conclusion: vp's internal shell emulator does **not** perform pathname expansion (globbing) at all. Every wildcard is passed through as a literal argument. `bun run`, in contrast, delegates to the system shell and gets shell glob expansion.

The reason `**/*.nix` happens to "work" under `bun run` for the current `nix/` tree is incidental: shell globstar behavior depends on the active shell. Files happen to all live exactly one directory deep, so the current pattern matches all of them. This breaks the moment a deeper file is added.

## Decision

For npm scripts that must run under `vp run`, **do not rely on shell glob expansion**. Use `$(find ...)` command substitution instead, which the vp shell emulator does support.

```json
{
  "scripts": {
    "check": "nixfmt --check $(find . -name '*.nix')",
    "fix": "nixfmt $(find . -name '*.nix')"
  }
}
```

This rule applies to any future workspace package whose scripts need to enumerate files by pattern (formatters, linters, code generators, etc.) when those scripts are invoked via `vp run` / `vp check` / `vp run --filter`.

### Rationale

- vp emulator behaviour is observed and stable; relying on it not expanding globs is the correct invariant.
- `find` is GNU-coreutils-portable and produces real recursion regardless of shell capabilities, so the script remains correct as the directory grows.
- Command substitution (`$(...)`) is supported by both vp's emulator and `/bin/sh`, so the same script works under both runners.

### Non-goals / alternatives considered

- **Configure a different script shell** (e.g. `/bin/bash` with `shopt -s globstar`): would only affect package-manager script execution, not `vp run`. Does not solve the actual problem.
- **Package-manager shell settings**: these are package-manager settings, not vp settings. They do not affect vp's behaviour.
- **Inline file lists**: brittle, must be hand-maintained.
- **Per-tool config files** (e.g. an editorconfig-like nixfmt manifest): nixfmt 1.2 does not support directory traversal; explicit file arguments are required.

## Impact

- **`nix/package.json`** uses `$(find . -name '*.nix')` for `check` and `fix` (already in place).
- **Future workspace packages** (e.g. potential `lua/`, `sh/`, `proto/` workspaces) that need to enumerate files in scripts run by vp must follow the same pattern.
- **Reviewers** should reject `**/*.x` style globs in `package.json` scripts that are intended to run under `vp run`, unless the script is explicitly only ever invoked via `bun run`.
- No runtime / build impact; this is a workspace tooling convention.
