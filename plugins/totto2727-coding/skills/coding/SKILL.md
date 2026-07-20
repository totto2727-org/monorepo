---
name: coding
description: >-
  totto2727's coding conventions across all languages. Use this skill when
  writing or reviewing code in any language (TypeScript, MoonBit, etc.) to
  obtain language-agnostic principles plus pointers to language-specific best
  practices and external specification references. Routes to per-language
  index skills (`ts.md`, `mbt.md`) for concrete patterns, and to
  sibling skills (`docs-moonbit`, `docs-components-build`) for external spec
  reading material. Common triggers: "coding conventions", "language
  conventions", "how should I write X in TypeScript / MoonBit", "look up
  totto2727 coding rules", "check the project coding style", "Effect Layer
  patterns", "@totto2727/fp usage", "MoonBit CLI", "admiral command",
  "admiral Context", "async CLI callback".
  Do NOT use for: test-specific conventions (use the sibling `test` skill),
  CI / build / monorepo orchestration (use `vite-plus`), framework-specific
  application patterns (use `remix` or other dedicated skills).
---

# Coding Conventions (totto2727)

This skill is the single hand-written entry point for **how to write code in this repository**. It carries the language-agnostic principles that apply everywhere, then routes to a language-specific index for concrete patterns, and finally to external specification reference skills when an authoritative upstream document is needed.

The companion `test` skill (sibling under this plugin) covers test-specific conventions; this skill stays focused on production code style and design.

## How to use this skill

1. Read the **Language-agnostic principles** section first. They apply regardless of which language you are writing.
2. Open the **Language index** entry for the language you are working in.
   That Tier-2 file (`references/<lang>.md`) lists the in-plugin detail files (Tier 3) plus any external skills you should also load.
3. If you need to consult an upstream specification (MoonBit language reference, Vercel components.build spec), follow the **External spec references** section to the dedicated sibling skill.
4. For test conventions, switch to the `test` skill — coding and test rules are intentionally split so each can have its own activation context.

## Language-agnostic principles

The following principles are non-negotiable starting points for any code landing in this repository. Language-specific files refine them; they never override them.

### Type safety first

Express invariants in the type system whenever the language permits it. Prefer narrow types over `any` / `unknown` / opaque strings. Type assertions (`as` in TypeScript, equivalents elsewhere) are a code smell — only allow them when the language type system genuinely cannot encode the invariant (e.g. `: unknown` in a public function parameter that will be validated at runtime). The cost of a missing type is paid by every future reader, not just the author.

### Locality of side effects

Push side effects (I/O, mutation, randomness, time) to the edges of the program. Pure functions in the middle. Effect-based languages (TypeScript with Effect, MoonBit with explicit error returns) make this enforceable; in plainer languages it remains a discipline. The goal: a function's signature should tell the truth about what it does. A signature that returns `T` but silently writes to a file is a bug waiting to happen.

### Naming as intent

Names are the primary documentation. A good name communicates _what the caller can rely on_, not _how it is implemented_. Prefer `fetchUserProfile(id)` over `getUserData(id)`; the former tells you the operation may fail and may hit the network, the latter hides both. Avoid abbreviations unless they are domain-standard (`URL`, `ID`, `HTTP`). Mirror the established vocabulary of the surrounding code rather than inventing synonyms.

### Testability

Code that is hard to test is hard to maintain. If a function requires a fifteen-step setup to exercise, the function (or its dependencies) is probably wrong. Practical rules:

- Inject dependencies at the boundary; do not reach for a global / singleton inside the function body.
- Keep cyclomatic complexity low — if you cannot enumerate the branches in your head, split the function.
- Make failure modes explicit (typed errors, `Result<T, E>`, `Effect<…, E>`) so tests can target them by tag rather than by error message string.

### Small, reviewable units

Prefer many small composable units over a single large one. The cost of a large abstraction is paid every time someone has to understand it; the benefit accrues only to the (often imagined) caller who would otherwise duplicate logic. When in doubt, write the duplication first; extract the abstraction only after the third copy.

### Explicit over clever

If a clever construct saves three lines but costs the reader thirty seconds of "wait, what does this do?", it is the wrong tradeoff. Pattern matching, guard clauses, and early returns usually beat nested ternaries and single-letter helpers. Comment _why_ something non-obvious is the way it is — never _what_ the code does (the code itself says that).

### Consistency with the surrounding code

A house style applied consistently is more valuable than the "best" style applied haphazardly. Before introducing a new pattern, look for existing prior art in the same package. If you must diverge, leave a one-sentence comment explaining why.

## Language index

Each language has a Tier-2 index file under `references/`. Open the index for your language to find concrete patterns, library conventions, and related external skills.

- **TypeScript** — see [`references/ts.md`](references/ts.md).
  Use when writing or reviewing TypeScript code (Effect, Hono, Remix, `@totto2727/fp`, monorepo packages under `js/`).
- **MoonBit** — see [`references/mbt.md`](references/mbt.md).
  Use when writing or reviewing MoonBit code (packages under `mbt/`).

Adding a new language follows the same shape: create `references/<lang>.md` as the index, add `references/<lang>/<topic>.md` detail files for each concrete topic, and append a bullet to the list above.

## External spec references

Authoritative upstream specifications live as **independent sibling skills inside this plugin** so that each carries its own activation `description:` and can be discovered directly when a question is purely about the upstream document. The links below are entry points to those sibling skills, not in-plugin reference files.

- [`docs-moonbit`](../docs-moonbit/SKILL.md) — MoonBit language reference (syntax, types, functions, methods, deriving). Auto-generated from the official MoonBit documentation. Open this when answering "what does the MoonBit language itself say about X?", as opposed to "how do we write MoonBit in this repository?" (which is the `mbt.md` index above).
- [`docs-components-build`](../docs-components-build/SKILL.md) — Vercel `components.build` open standard for modern UI components (composition, accessibility, polymorphism, design tokens, registry distribution).
  Auto-generated from `https://www.components.build/`. Open this when designing reusable component APIs or building a design system.

These two skills are auto-regenerated by the Deno scripts under `.script/`; do not hand-edit their bodies. The slash commands `update-docs-moonbit` and `update-docs-components-build` (under `.claude/skills/` of this plugin) are the supported regeneration entry points.

## Related skills

- **[`test`](../test/SKILL.md)** (sibling skill in this plugin) — test-specific conventions (test independence, observable assertions, fixture hygiene), with the same 3-tier shape (entry SKILL.md → `<lang>-skill.md` index → detail files). Always pair `coding` with `test` when writing real code.
- **`vite-plus`** (external skill, npm-package-bundled) — the project's unified toolchain (Vite / Vitest / monorepo orchestration). Referenced from `references/ts.md` for concrete `vp run`, `vp test`, and `vp check` usage.
- **`dev-workflow`** (sibling plugin) — Specifies how new conventions themselves are introduced (Intent → Research → Design → QA → Tasks → Implementation → Review → Validation → Retrospective). Open this when proposing a non-trivial change to the rules in this skill rather than applying them.

## Out of scope for this skill

- Test conventions (use the `test` skill).
- CI / build pipeline configuration (use `vite-plus` and `Taskfile.yml`).
- Project-level architecture decisions that span multiple packages (use `docs/adr/`).
- One-off code review heuristics that do not generalize (keep them in PR comments).
