# Test Design Workflow

> Document type: concrete test-design procedure.

## Inputs

At minimum, read:

- The user's stated goal and success criteria.
- Any available intent/specification document.
- Any available design or architecture document.
- Project-specific testing constraints when they affect feasibility, while keeping the design artifact framework-agnostic.

If success criteria are implicit, first rewrite them as `SC-N` entries in observable terms. If a criterion cannot be observed or verified, stop and ask for clarification instead of inventing a test.

## Procedure

1. Assign success criterion IDs (`SC-1`, `SC-2`, ...).
2. Rewrite each criterion into observable behavior. Replace vague words like “fast”, “easy”, or “safe” with measurable or reviewable outcomes.
3. Decide the execution actor for each test case:
   - `automated` — reproducible by CI or a local test command; preferred when possible.
   - `ai-driven` — requires contextual browser/tool operation that an AI agent can perform and report.
   - `manual` — requires human judgment, physical operation, UAT, or subjective review.
4. Decide the verification style:
   - `assertion` — exact equality/state judgment.
   - `scenario` — sequential multi-step behavior.
   - `observation` — threshold, metric, count, latency, or trend judgment.
   - `inspection` — qualitative review such as UX, layout, logs, or document quality.
5. Create essential test cases (`TC-NNN`) for behaviors expressible at the spec/design level.
   - Aggregate multiple assertions into one test case only when one setup and one system-under-test invocation produce multiple observable facts for the same outcome.
   - Split cases when verification invokes the system under test multiple times with different arguments or input, even when those invocations share a fixture.
   - When assertions are aggregated, draw their observation nodes converging on the same `TC-NNN` leaf so the flow makes the shared test-case boundary explicit.
   - When a numbered case is implemented as an executable test, include its number in the title using a stable scope. Use the exact design ID for standalone QA artifacts and follow the [embedded function-flow rules](qa-flow.md#embedded-executable-function-flows) for co-located executable documentation.
6. Leave implementation-driven cases (`TC-IMPL-NNN`) empty unless implementation details are already known; those are normally appended later when concrete code reveals defensive branches.
7. Create a coverage table mapping every `SC-N` to at least one `TC-NNN`.
8. Create `qa-flow.md` with one or more Mermaid `flowchart TD` diagrams. Every leaf must be a `TC-NNN`, `TC-IMPL-NNN`, or `skip: <reason>`.
9. Present both artifacts for human review. Do not replace the artifacts with a prose-only summary.

## Two-axis tagging rules

Every test case must have both axes filled.

| Axis  | Values                                                  |
| ----- | ------------------------------------------------------- |
| Actor | `automated` / `ai-driven` / `manual`                    |
| Style | `assertion` / `scenario` / `observation` / `inspection` |

Forbidden combination:

- `automated × inspection` — automation cannot perform subjective inspection without an explicit oracle.

Combinations requiring a note:

- `ai-driven × assertion`
- `manual × assertion`
- `manual × observation`

The note must explain why a more reproducible actor/style is not appropriate.

## Design decision guide

- Unit-style behavior usually maps to `automated × assertion`.
- Integration behavior usually maps to `automated × assertion` or `automated × scenario`.
- End-to-end behavior usually maps to `automated × scenario` when deterministic, or `ai-driven × scenario` when contextual operation is needed.
- Performance, counts, and thresholds map to `automated × observation` when measurable.
- UX, visual polish, and subjective document review map to `manual × inspection` unless a visual automation oracle is explicitly available.

## Exit criteria

- Every success criterion is covered by at least one essential test case.
- Any test case with `Target SC = (none)` has a mandatory reason.
- Every test case has valid Actor and Style values.
- `automated × inspection` is not used.
- Every Mermaid leaf follows the numbering scheme for its artifact: test-case IDs for standalone QA flows or function-local numbers for embedded executable flows.
- Every aggregated assertion path converges on one test case leaf, while different invocation arguments or input lead to separate test case leaves.
- Every executable test implementing a numbered case includes its scoped case number in its title.
- Hierarchical function-local numbers are used only with matching split flowcharts.
- The design is useful for a human reviewer without reading implementation code.
