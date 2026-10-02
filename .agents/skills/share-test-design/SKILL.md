---
name: share-test-design
description: >-
  Test-design principles for observable cases, risk-based coverage, verification methods, and evidence. Use when designing or reviewing test plans and QA reports.
---

# Shared Test Design

Design tests around the behavior that matters and the evidence needed to judge it, not around a prescribed document or diagram.
Apply [documentation-principles](../documentation-principles/SKILL.md) to human-facing plans and reports.
These principles complement [share-test](../share-test/SKILL.md), which owns language-independent testing philosophy.

## Observable outcomes, not invented requirements

A useful case connects a requirement or risk to a concrete input or situation, an observable outcome, and a basis for deciding whether that outcome is correct.
The user's goal, specification, architecture, and project constraints inform that connection.
Do not treat current implementation behavior as the sole source of expected behavior.

Qualitative terms such as “fast,” “easy,” and “safe” need a measurable or reviewable meaning agreed for the task.
A latency criterion needs a threshold and workload; a usability criterion needs a task and a basis for judging completion.
Do not invent a numerical target or claim that a convenient proxy proves the original requirement.

**If a criterion cannot be observed or verified, stop and ask for clarification instead of inventing a test.**
This boundary applies regardless of presentation format or verification method.

## Coverage follows behavior and risk

Success criteria should have identifiable test coverage, with gaps made explicit rather than hidden behind aggregate test counts.
A table, descriptive names, links, or a short explanation can establish the connection; universal IDs and tags are not required.
A planned case is not evidence that its requirement passed.

Consider meaningful input partitions, boundaries, failure paths, and state transitions in addition to the happy path.
Include interactions across external systems, adapters, persistence, cancellation, or retries when they affect the promised behavior.
Prioritize by failure impact, likelihood, and uncertainty rather than by the number of cases or implementation branches.

Distinguish specification-level cases from implementation-driven risks such as library parse failures, serialization differences, filesystem behavior, and adapter boundaries.
Implementation-driven cases are useful when they protect a real invariant or regression risk, not merely because a branch exists.
Explain the reason for cases that do not directly map to a stated success criterion.
Do not invent implementation details to fill an empty category.

## Match the verification method to the claim

Choose an observation boundary capable of proving the behavior.
A unit assertion can establish a local invariant; an integration or end-to-end scenario can establish behavior across real boundaries.
A mock or synthetic fixture may isolate a useful property but does not establish that the real integration works.

Prefer reproducible automation for deterministic checks when its maintenance cost is justified by the risk.
Contextual AI operation can support browser or tool scenarios that require adaptive interaction.
Human review remains useful for subjective judgments, physical operation, and user acceptance.
Explain important reproducibility limitations and why the chosen method is appropriate, rather than assigning mandatory actor/style tags.

Execution and judgment are separate concerns.
An automated runner, AI agent, or human can observe a result, but each still needs an explicit basis for evaluating it.
Exact assertions, sequential scenarios, metric observations, and qualitative inspection are useful ways to think about evidence, not a closed taxonomy.
Automation does not turn a subjective inspection into an objective check without a defined oracle.

Performance claims need the relevant environment, workload, sampling, and threshold.
Qualitative reviews need review criteria and an honest account of whose judgment was applied.
A one-off successful AI or manual run does not demonstrate CI reproducibility.

## Cases should explain failures

Group assertions when they describe one coherent outcome from the same setup and invocation.
For example, a rejected write can be checked both for its error response and for the absence of partial persistence.
Separate independently meaningful inputs and behaviors so a failing result identifies what broke; shared fixtures alone do not make cases equivalent.
Parameterized cases can express the same contract across input partitions without duplicating prose.

A stateful scenario may deliberately involve multiple invocations when their sequence is the behavior under test.
Keep the relevant initial state, actions, and observations visible rather than splitting away the interaction being verified.
For related functions sharing a contract, make the shared scope clear and cover type-specific or conversion behavior separately where it differs.
Neither case boundaries nor executable test titles depend on diagram leaf numbering.

## Evidence must support the reported conclusion

Keep expected outcomes distinct from actual observations.
Distinguish cases that were designed, executed, passed, failed, blocked, or intentionally not run.
Tie execution claims to available results, logs, artifacts, or reproducible observations, and state relevant environment or access limitations.
Do not report a skipped, deferred, or blocked check as passing, or a proxy check as full acceptance coverage.

Explain why a branch is out of scope or intentionally untested when that affects confidence.
A coverage gap remains a gap even when its deferral is justified.
Unobservable or unverifiable criteria still require the clarification boundary above.

## Presentation serves the reader

Use any format that makes the design or evidence easy to evaluate: concise prose, a list, a table, executable examples, a diagram, HTML, or an existing project format.
There is no required `qa-design.md` / `qa-flow.md` pair, Mermaid diagram, numbering scheme, actor/style taxonomy, or file location.
Avoid maintaining parallel representations unless each helps the reader and can stay consistent.

Use a flow diagram when branching, ordering, or state transitions are harder to understand in text.
Use stable names or IDs when readers need to refer across artifacts, not as a universal naming contract for tests.
[Presentation examples](references/presentation.md) illustrate several choices without defining a workflow or required output.

## Responsibility boundaries

This skill provides test-design decision criteria, not an execution procedure, CI policy, approval sequence, or test-runner command reference.
Use [js-test](../js-test/SKILL.md), [mbt-test](../mbt-test/SKILL.md), or [rust-test](../rust-test/SKILL.md) for language-specific executable implementation.
