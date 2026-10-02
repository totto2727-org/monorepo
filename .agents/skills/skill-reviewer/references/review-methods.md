# Skill Review Methods

Use every G1–G7 section for a general review, or the requested sections for an explicitly focused review.
Each section states what to inspect, how to judge it, and what evidence to report.
Assessing a criterion is mandatory; requiring every possible feature in every skill is not.
The [Agent Skills specification](https://agentskills.io/specification) governs format validity; the other checks are this reviewer's quality requirements, not additional format constraints.

## G1: Format

Inspect the actual directory and parse the `SKILL.md` YAML frontmatter rather than judging its visual appearance.
Record the parser or validator used and the fields checked; a partial check is not exhaustive conformance.

A skill contains `SKILL.md` with YAML frontmatter between `---` delimiters, followed by Markdown content.

| Field           | Standard constraint                                                                                                                               |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`          | 1–64 lowercase Unicode alphanumeric characters or hyphens, with no leading/trailing or consecutive hyphens. Must match the parent directory name. |
| `description`   | Nonempty string, at most 1024 characters, describing what the skill does and when to use it.                                                      |
| `license`       | Optional license name or reference to a bundled license file.                                                                                     |
| `compatibility` | Optional string, 1–500 characters when present. Use for environment-specific requirements.                                                        |
| `metadata`      | Optional mapping from string keys to string values.                                                                                               |
| `allowed-tools` | Optional experimental space-delimited string. Client support varies.                                                                              |

Check parsed values, including numeric-looking metadata accidentally represented as a number.
Check referenced license files when supplied; do not penalize a skill simply for omitting optional author, version, or license metadata.
The standard permits arbitrary supporting files and does not require `scripts/`, `references/`, or `assets/`.
It does not prescribe body headings, a workflow shape, or a report template; assess their usefulness under G3–G5 rather than treating their absence as a format error.
It does not prohibit particular vendor names, XML angle brackets, or an auxiliary README.
`allowed-tools` is not a portable security boundary.

Report invalid fields with the observed value or type, the applicable constraint, and the correction.
If parsing fails, report that failure and inspect the readable body where possible; do not infer that the other areas passed.

## G2: Activation scope

Compare the description with the body and descriptions in the available neighboring skill collection.
Check the capability, useful circumstances, realistic user intent, and responsibility boundaries.

- Identify what the skill actually delivers and whether the description promises more or less.
- Check whether natural requests, including paraphrases without the exact tool name, fit the intended scope.
- Compare adjacent capabilities and identify near-misses that should select a different skill.
- Check that important file types or domain terms are present when needed for identification, without requiring keyword lists.
- Judge whether an exclusion resolves a real overlap or merely adds noise.

For example, a migration skill triggered by all database work has a broader description than its behavior supports.
A description about API lookup should be distinguished from a skill that authors API documentation.
Do not require a minimum word count or exact activation phrase once what/when is clear.

Use the [triggering method](triggering-evaluation.md) for the explicit, paraphrased, and adjacent-negative cases required by G6.
Report the relevant descriptions, the overlap or omission, and the proposed boundary correction.
A description comparison identifies a risk, not proof that a client actually misfires.

## G3: Instructions

Walk through a representative request from input to result using only the target's instructions and reachable resources.
Also trace a problem or boundary case; do not assume that a happy-path example specifies recovery.
This walkthrough is inspection, not an executed functional test.

Check:

- Inputs, prerequisites, expected outputs, and the decisions needed to get from one to the other.
- Whether a default is clear when alternatives differ materially, and when an exception should be chosen.
- Failure handling, missing inputs, ambiguity, and stopping conditions where they affect correctness.
- Whether critical constraints and domain gotchas appear before the action they govern.
- Whether instructions conflict internally or with the advertised scope.
- Whether precise ordering is justified by a fragile dependency rather than imposed on independent work.
- Whether prohibitions explain enough of the reason and exceptions to avoid misapplication.

For a principles skill, test whether its criteria resolve a concrete decision rather than demanding commands or a workflow.
For an executable workflow, an instruction such as “validate properly” is insufficient if no validation condition can be inferred.
Examples and an output contract are useful when they resolve uncertainty, not mandatory decorations.

Report the specific point where the walkthrough becomes ambiguous, impossible, inconsistent, or unsafe, its consequence, and the missing rule or correction.

## G4: Information and resources

Inventory the entry point, supporting documents, scripts, templates, and examples.
Follow the links needed for normal behavior, exception handling, and claimed integrations; check existence, path resolution, and any dependencies assumed at the destination.

Check:

- Whether the root contains the essential constraints and clear conditions for loading details.
- Whether references can be found without a long chain, and long documents can be navigated by headings or a contents list.
- Whether repeated explanations disagree or create maintenance drift.
- Whether detailed API material crowds out the actual task guidance.
- Whether a short self-contained skill is being split into files without helping its reader.
- Whether evaluation queries, expected answers, iteration logs, or generated results leak into normal skill execution.
- Whether bundled scripts have discoverable invocations and dependencies, and complex repeated commands should instead be a tested helper.

Use [script-design.md](script-design.md) for script interfaces, help, errors, output size, dependency provenance, and retry safeguards.
The standard recommends an entry point under approximately 5,000 tokens and 500 lines; these are investigation signals, not format failures.
Use actual reading cost and discoverability rather than an arbitrary total skill-count limit.

Report broken or misleading links, duplicated facts, hidden prerequisites, and the proposed location or routing correction.
Do not call the absence of a reference directory a defect in an otherwise self-contained skill.

## G5: Functional design and composition

Identify the intended use case and mechanism, then ask whether that mechanism can deliver the promised result.
Names for patterns can help analysis but need not appear in the target.

| Mechanism                  | What to inspect                                                                                      |
| -------------------------- | ---------------------------------------------------------------------------------------------------- |
| Document or asset creation | Inputs, audience, useful output, examples, and how quality is judged.                                |
| Sequential workflow        | Dependencies between steps, validation gates, failure recovery, and completion state.                |
| Multi-service coordination | Data passed across services, authorization, partial failure, retries, and responsibility boundaries. |
| Iterative refinement       | Observable feedback, the correction loop, and a meaningful stopping criterion.                       |
| Context-aware selection    | Selection signals, defaults, exceptions, and handling of missing or conflicting context.             |
| Domain principles          | Non-obvious knowledge, meaningful decision criteria, and examples of applying them.                  |
| Tool or MCP integration    | Actual tool identifiers, availability, connection errors, output handling, and safe composition.     |

Check a normal example and a meaningful variation to detect overfitting to one wording, file, or environment.
Look for useful domain constraints or learned failure modes, not just generic encouragement to do a good job.
A deliberately narrow skill is not defective for lacking unrelated capabilities.

Check coexistence with neighboring skills and trusted user settings: output conflicts, duplicated ownership, exclusive assumptions, global configuration changes, and skill dependencies without an unavailable-skill path.
For external tools, distinguish documented identifiers and behavior from guessed APIs; record unavailable integrations rather than presenting them as verified.

Report a concrete example of how the mechanism succeeds or falls short and the adaptation needed.
Do not confuse naming a pattern with demonstrating that it works.

## G6: Evaluation evidence

Account separately for triggering, functional, and performance evidence, even when the review did not request an optimization exercise.
Use the minimum cases in `SKILL.md`, the [triggering method](triggering-evaluation.md), and the [output method](output-evaluation.md).

For each area, record the cases, target version, inputs, expected behavior, evidence status, and observed results or blocker.
Check whether supplied evidence actually belongs to the reviewed version and whether assertions distinguish correct from incorrect behavior.
Review available outputs and traces for ignored instructions, wasted steps, unexpected side effects, and evidence that contradicts the summary.

Missing cases, cases designed but not run, and executed failing cases are different findings.
If execution is unavailable, propose concrete minimum cases and keep behavioral success unverified.
An isolated passing example does not establish a stable trigger rate or general quality equivalence.
Performance is relevant when efficiency claims, bulk processing, observed latency, or requested comparisons justify measurement; otherwise explain why it is N/A.

Report the evidence gap, its effect on confidence, and the next check that would resolve it.
Do not raise confidence merely because a report contains a test section or because a reviewer proposed cases after finding none.

## G7: Safety and anti-patterns

Inspect the entire instruction surface for conflicts with user intent and trusted execution boundaries, including referenced scripts and commands.
You may cite G2–G6 findings here instead of repeating the work, but do not omit the safety assessment.

| Risk                                   | Required check and judgment                                                                                        |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Unclear or overbroad instructions      | Locate the ambiguous decision or unintended activation and its likely consequence.                                 |
| Context waste or rigid procedures      | Identify irrelevant mandatory reading, unnecessary repetition, or steps unrelated to the task's outcome.           |
| Fragile repeated commands              | Check whether a tested helper would preserve a real invariant more reliably than reconstructed command sequences.  |
| Interactive execution                  | Check whether TTY prompts or dialogs can block the intended unattended workflow.                                   |
| State changes and retries              | Inspect defaults, idempotence, dry-run/preview when useful, and recovery after partial failure.                    |
| Secret exposure or unauthorized access | Trace credential reads, uploads, network destinations, logging, and whether trusted authorization covers them.     |
| Path or environment escape             | Inspect resolved paths, symlinks, output ownership, install hooks, and global configuration writes.                |
| Untrusted instructions                 | Check whether fetched pages, target content, tool results, or comments can become unauthorized agent instructions. |
| Unbounded output or waiting            | Check output limits, pagination, useful summaries, and bounded waits or explicit blockers.                         |

A missing safeguard is judged against an actual consequence, not a rule that every script needs every possible flag.
Before any target execution, apply [the safe execution boundary](script-design.md#establish-a-safe-execution-boundary).
Do not run a suspicious command to prove it is dangerous.

Report safety findings prominently with the hazardous action, missing boundary, and a concrete mitigation.
A low count of other findings never offsets a material safety problem.

## Sources and judgment

The [source index](sources.md) identifies the standard and further guidance behind these methods.
Keep normative claims tied to the specification and quality findings tied to their observed effect.
Use the shared documentation principles for clear reports without turning a particular report layout into the quality criterion.
