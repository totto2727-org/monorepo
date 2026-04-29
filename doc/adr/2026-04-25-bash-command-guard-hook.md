---
confirmed: false
---

# ADR: Bash Command Guard via PreToolUse Hook (Deno)

## Context

Repository-level constraints have accumulated that should never be bypassed locally — for
example, never running with `CI=true`, never using `<package-manager> ci` outside the CI
pipeline, and never using `git -C` (which forces ambiguous working-tree semantics and
triggers permission prompts in this Claude Code setup).

These rules currently live in MEMORY (`feedback_no_ci_env`) or in CLAUDE.md hints, which
are advisory: a forgetful agent can still issue them. We want **enforcement**, not just
advice, so the user does not need to repeat the same correction across sessions.

Constraints shaping the design:

1. **Plugin-local**: this guardrail belongs to `plugins/totto2727`, not to a per-project
   tool — it should be opt-in by installing the plugin.
2. **No Node/TS toolchain coupling**: the hook must run before any project install step
   and must not depend on `pnpm`/`vp`/`vite` being available. The repo already uses Deno
   for one-off scripts (cf. existing `**/.script/**` ignore pattern in `vite.config.ts`).
3. **Zero external dependencies**: anything imported pulls a network fetch on first run,
   which is undesirable for a hook that fires on every Bash tool call.
4. **Per-rule testability**: rules are independent units of behavior; each one needs its
   own tests so we can iterate on a single rule without touching the others.
5. **Multi-hook future**: we expect more hooks under the same plugin (one per concern),
   not a single megascript.

## Decision

### 1. Runtime: Deno

Implement the guard as a Deno script invoked from a Claude Code `PreToolUse` hook with
`matcher: "Bash"`. Deno is preferred over Node because:

- It is already on PATH via devbox.
- It runs `.ts` files directly, no build step.
- Default-deny permissions mean the hook cannot read the filesystem or network even if
  buggy; we pass `--no-prompt` and no `--allow-*` flags.
- Built-in `Deno.test` removes the need for a test framework dependency.

The script does not import anything outside its own directory, so first-run latency is
just Deno's typecheck of the local files.

### 2. Plugin Layout: `script/<hook-name>/`

```
plugins/totto2727/hooks/
├── hooks.json                       # Claude Code hook registration
└── script/
    └── bash-guard/                  # one directory per hook
        ├── deno.json
        ├── main.ts                  # entrypoint
        ├── lib/                     # shared helpers (tokenizer, etc.)
        │   ├── shell.ts
        │   └── shell.test.ts
        └── rules/
            ├── types.ts             # Rule / RuleViolation
            ├── index.ts             # registry
            ├── no-ci-env.{ts,test.ts}
            ├── no-package-manager-ci.{ts,test.ts}
            └── no-git-c.{ts,test.ts}
```

Each future hook gets its own sibling directory under `script/`, with its own
`deno.json`, so hooks are independently versioned and testable.

### 3. Rule Contract

Each rule exports an object matching:

```ts
type Rule = {
  readonly name: string
  readonly check: (command: string) => RuleViolation | null
}
type RuleViolation = {
  readonly rule: string
  readonly message: string     // what is forbidden
  readonly resolution: string  // how to comply
}
```

Rules are free to use either regex or the shared shell tokenizer. They are aggregated in
`rules/index.ts` and run in registration order; **all** matching rules surface their
violations on a single deny response, so the user sees every problem at once.

### 4. Shell Tokenizer (`lib/shell.ts`)

A minimal tokenizer that respects single/double quotes, backslash escapes, and emits
operator tokens (`;`, `&&`, `||`, `|`, `&`). It is **not** a full shell parser — it does
not expand variables, evaluate substitutions, or handle redirections. The accompanying
`splitCommands` utility splits an argv stream at operator boundaries so each rule can
inspect each chained command independently. `skipEnvPrefix` normalizes leading
`FOO=bar`/`export FOO=bar` prefixes.

### 5. Hook I/O Contract

`main.ts` reads the Claude Code PreToolUse JSON payload from stdin, ignores anything that
is not a `Bash` tool call, and emits a single JSON document on stdout when one or more
rules fire:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Bash command blocked by hook:\n\n[<rule>] <message>\n  Resolution: <resolution>"
  }
}
```

The script always exits 0 — the deny decision is encoded in the JSON, not the exit code.

### 6. Initial Rules

| Rule                       | Detection                                                                                                                  |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `no-ci-env`                | `CI=<truthy>` env-prefix tokens (and `export CI=<truthy>`); does not flag the literal inside quoted strings.               |
| `no-package-manager-ci`    | `<pm> ci` for `pm ∈ {npm, pnpm, yarn, bun, vp}`, accounting for env prefixes and command chaining.                         |
| `no-git-c`                 | `-C` token in `git`'s **global option region** (before the subcommand), regardless of order; skips value-taking options.   |

`no-git-c` deliberately does not flag `-C` after the subcommand (e.g. `git diff -C`,
`git log -C`) since those are different flags belonging to the subcommand.

### 7. Toolchain Exclusion

Add `**/hooks/script/**` to both `lint.ignorePatterns` and `fmt.ignorePatterns` in
`vite.config.ts`. Verification of these files is performed exclusively via Deno:

```bash
deno lint   # in plugins/totto2727/hooks/script/bash-guard
deno check main.ts rules/index.ts ...
deno test
```

## Impact

- New plugin component under `plugins/totto2727/hooks/script/bash-guard/` (13 files, 58
  unit tests, 0 external dependencies).
- `plugins/totto2727/hooks/hooks.json` gains a `PreToolUse` entry alongside existing
  `SessionStart`/`Stop` exocortex hooks.
- `vite.config.ts` ignore patterns extended so `vp check` skips Deno-only sources.
- Anyone activating the `totto2727` plugin will have the three rules enforced on every
  Bash invocation that Claude Code mediates. The hook does not affect commands run
  outside Claude Code.
- Future hooks can be added as siblings under `script/` (e.g. `script/<other-hook>/`)
  without disturbing this one.
