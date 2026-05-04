---
name: test
description: >
  Tier-1 entry point for totto2727-flavoured testing conventions across all languages used in this monorepo.
  Defines language-agnostic test principles (intent-revealing names, mock minimisation, observable assertions,
  framework independence) and routes the reader to per-language test indexes under `references/`. Use when
  writing new tests, reviewing test code for quality, deciding test granularity / boundary coverage, or choosing
  whether a behaviour deserves a spec-level test versus an implementation-incidental test. Sibling of `coding`
  (code conventions live there); this skill covers test conventions only.
  Activation triggers: "write a test", "test conventions", "how should I test X", "review test quality",
  "test naming", "mocking guidance", "totto2727 test rules". Do NOT use for: code conventions / style
  (use `coding`), MoonBit language reference (use `docs-moonbit`), components-build spec lookup
  (use `docs-components-build`), test framework CLI usage (refer to the relevant external skill, e.g.
  `vite-plus` for Vitest via `vp test`).
---

# Test Conventions (totto2727)

This skill is the Tier-1 entry point for testing conventions in projects authored or maintained by
totto2727. It captures the **language-agnostic principles** that apply to every test we write, then
routes the reader to a per-language Tier-2 index for concrete patterns and framework-specific tooling.

For code conventions (production code style, naming, error handling, DI, etc.), see the sibling
[`coding`](../coding/SKILL.md) skill.

## Language-agnostic principles

These principles apply regardless of language or test framework. Where a per-language convention
contradicts one of these, the per-language file (`references/<lang>-*.md`) wins because it has more
context — but contradictions should be rare and explicit.

### 1. Test names express intent, not mechanics

A test name should read like a behavioural assertion ("`Point to_bbox - without BBox`",
"`orient2d - clockwise`"), not a mechanical restatement of the code under test
("`testFooFunction1`"). The reader should learn **what behaviour is guaranteed** from the name alone,
without opening the body. Use natural-language scenario phrasing; avoid CamelCase noise inside
descriptions.

### 2. Avoid mock overuse; prefer real collaborators

Mocks are a tool for isolating a unit from **slow, non-deterministic, or external** collaborators
(network, clock, filesystem under test). They are **not** a tool for compensating for a bad design.
Reach for mocks only when:

- The collaborator is genuinely external (HTTP, DB, time, randomness).
- A real collaborator would make the test non-deterministic or slow enough to harm the feedback loop.
- The behaviour under test is explicitly about the protocol with that collaborator.

If you find yourself mocking N internal pure modules to test the (N+1)-th, the design — not the test —
is the problem. Refactor first; test the refactored seam afterwards.

### 3. Tests are observable acceptance checks

Every test must produce a **boolean pass/fail observable from the test runner's exit code**. No
"prints something and the human eyeballs it". This is enforced framework-agnostically because every
mature test framework already exposes this contract; the rule is about the **author's** habit, not
the framework.

Concrete corollaries:

- Use exact-match assertions (`assert_eq`, `expect(...).toEqual(...)`, `debug_inspect(value, content="...")`)
  over fuzzy `toContain` / regex when the value is fully known.
- Snapshot-style assertions (`debug_inspect`, `toMatchInlineSnapshot`) are acceptable when the value
  is large but deterministic. Pass the **direct return value** of the function under test, not a
  derived property like `.length`.
- Tests that throw / panic must be tagged so the framework treats the throw as a pass
  (e.g. MoonBit `panic_<...>` test name prefix; Vitest `expect(...).toThrow()`).

### 4. One behaviour per test; no hidden conditionals

A single test asserts a single behaviour. If the body contains `if` / `match` / `try` blocks that
**branch the assertion**, split the test. The cost of three tests with three names is negligible;
the cost of debugging a green-but-actually-wrong combined test is enormous.

Multiple `expect` / `assert_eq` calls within one test are fine **iff** they all assert facets of the
same behaviour. They are not fine when the second assertion would be a different test name in
isolation.

### 5. Boundary values and error cases are mandatory, not optional

Every essential test (TC-NNN) covers the happy path **and** the boundary / error cases that the
spec or design implies. The implementer adds these as part of the task; they are not "nice to have".

When implementation surfaces a new boundary that was not visible at design time:

- If the boundary is **expressible at the spec level** → propose a TC-NNN entry to qa-design.md (
  reportable in implementation-log; the qa-analyst owns structural changes).
- If the boundary is **only visible at the language / framework / OS level** → append it as a
  TC-IMPL-NNN test under the implementation-incidental section.

The two are distinguished by ID prefix; both live in qa-design.md / qa-flow.md.

### 6. Framework independence at the design level

Test cases (TC-NNN) are described in qa-design.md at an abstraction level that does not commit to
Vitest-vs-Playwright-vs-MoonBit-runtime. Framework choice is a separate decision driven by the
language and the system under test (web app → Playwright; pure logic → Vitest / `moon test`).

This means: **the test description must read as "given X, when Y, then Z"**, not as "calls
`vi.fn().mockResolvedValue(...)` and asserts ...". The latter belongs inside the test body;
the spec belongs to the test name and qa-design.md row.

### 7. Tests are first-class production code

Tests share the linter, formatter, and type checker with production code (`vp check`, `moon check`).
A test that fails type-checking blocks the merge just like production code does. Do not weaken
type checks with `as any` / equivalent escape hatches inside tests.

## Language index

Pick the language you are writing tests in. Each Tier-2 index file lists in-plugin detail files
(language-specific test patterns) and external skill references (test runners / frameworks owned
outside this plugin).

- **TypeScript** — see [ts-skill.md](references/ts-skill.md). Routes to the `vite-plus` skill
  for the test runner (Vitest).
- **MoonBit** — see [mbt-skill.md](references/mbt-skill.md). Use when writing MoonBit unit tests
  (`test "..."` / `debug_inspect` / `.mbt.md` test files); routes to `mbt-bestpractice.md` for
  full conventions including naming, file format, and trait-method ambiguity resolution.

## Related skills

- [`coding`](../coding/SKILL.md) — Code conventions (production code style, language idioms, DI,
  error handling). Sibling skill in this plugin; consult it together with `test` when establishing
  conventions in a new project.
