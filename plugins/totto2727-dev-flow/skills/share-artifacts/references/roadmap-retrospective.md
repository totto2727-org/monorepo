# Reference: How to write `roadmap-retrospective.md`

## Purpose

In `roadmap` Step 4 (Roadmap Retrospective), **reflect on the entire roadmap** by aggregating the retrospectives or summaries of each underlying workflow-level execution while integrating roadmap-specific points (overview of milestone achievement / dependency graph validity / roadmap-specific improvement proposals). The goal is to extract **strategic-level knowledge** that can be applied when starting the next similar roadmap.

This document must include the following sections specific to the roadmap context:

- Overview of milestone achievement (list of the final states of `progress.yaml.milestones[]`)
- Reflection on dependency graph validity (whether the DAG confirmed in Step 2 was actually valid in operation)
- Aggregation of underlying workflow-level retrospectives or summaries (one paragraph per execution)
- Roadmap-specific improvement proposals (`progress.yaml` schema extension proposals, re-evaluation of the per-step reflection scope-out, milestone splitting granularity, etc.)

## Author / creation timing

- **Author:** `roadmap-retrospective-writer` Specialist (single instance)
- **Step:** `roadmap` Step 4 (Roadmap Retrospective)
- **Approval:** Main verdict (information sharing only with the user)

## File location (aggregated form + `roadmap-` prefix naming rule)

`docs/retrospective/roadmap-<roadmap-id>.md`

Under `docs/retrospective/`, workflow-level retrospectives and `roadmap` retrospectives can coexist in **a flat aggregation** (same pattern as `docs/adr/`). Name-space collisions between them are avoided by **prefixing the roadmap side with `roadmap-`**:

| Kind                     | Storage location                             | Example                                       |
| ------------------------ | -------------------------------------------- | --------------------------------------------- |
| Workflow-level execution | `docs/retrospective/<identifier>.md`         | `docs/retrospective/auth-foundation.md`       |
| `roadmap` roadmap        | `docs/retrospective/roadmap-<roadmap-id>.md` | `docs/retrospective/roadmap-oauth-rollout.md` |

This `roadmap-` prefix naming rule is duplicated in this document and in `roadmap/SKILL.md` (avoiding name collisions in a directory where workflow-level and roadmap retrospectives coexist).

`gls docs/retrospective/roadmap-*.md` can extract roadmap retrospectives in bulk. When the file count grows in the future and search-ability degrades, there is room to mechanically migrate to a sub-directory separation scheme `docs/retrospective/roadmap/<roadmap-id>.md` (the prefix scheme is adopted in this version).

## Lifecycle

The roadmap retrospective is operated as **a volatile report box**. Decisions to be persistently recorded are extracted into ADRs (General mode `docs/adr/` / Roadmap mode `docs/roadmap/<roadmap-id>/adr/`; mode determination in `share-adr/SKILL.md`) before the retrospective is deleted.

| Kind                  | Storage location                                | Lifecycle                                                                                    |
| --------------------- | ----------------------------------------------- | -------------------------------------------------------------------------------------------- |
| ADR                   | `docs/adr/` or `docs/roadmap/<roadmap-id>/adr/` | Persistent. Immutable once `confirmed: true`                                                 |
| Roadmap Retrospective | `docs/retrospective/roadmap-<roadmap-id>.md`    | Volatile. Deletable when its improvement items are consumed at the start of the next roadmap |

However, since `roadmap` is filed over a longer span than workflow-level executions, deletion frequency is lower than for workflow retrospectives. Keeping the most recent 1-2 roadmaps' worth is recommended.

## How to write each section

### Roadmap overview

In 1-3 paragraphs, what was achieved by the roadmap as a whole against the purpose of `roadmap.md`. Showing the number of underlying executions and the total elapsed period at the top makes it easier to survey.

### Overview of milestone achievement

List the final states of `progress.yaml.milestones[]`. Example table columns:

- `Milestone ID`
- `Title`
- `Final Status` (`completed` / `blocked` / `cancelled` / etc.)
- `Basis for completion judgment` (described against the "Goals (qualitative)" of `milestones/<milestone-id>.md`)
- `Linked workflow execution <identifier>` (transcribed from `workflow_identifiers[]`)

For milestones other than `completed` (e.g. ended in `blocked`, `cancelled`), state the rationale of the judgment and hand-off items to the next roadmap clearly in **this section or in "Hand-off to the next cycle"**.

### Reflection on dependency graph validity

Reflect on whether the milestone dependency DAG confirmed in Step 2 remained valid through actual operation. Aspects:

- **Dependencies that worked as intended**: starting / converging points were appropriate, parallel execution was operated as expected
- **Unnecessary dependencies**: in hindsight, A → B was not needed and progress could have been made without it; serialization was unnecessary
- **Missing dependencies**: there was an implicit dependency not in the DAG, causing rework in subsequent executions
- **Effective parallelism**: theoretical parallelism (DAG width) vs. actual number of concurrently launched executions

The validity issues raised here become hand-off items to the `roadmap-planner` of the next roadmap.

### Aggregation of underlying workflow-level retrospectives

Summarize the retrospective or summary of each underlying workflow-level execution in **one paragraph per execution**. Each paragraph should include:

- Execution `<identifier>`
- Linked milestone id (identified from `progress.yaml.roadmap.milestone.id`)
- Outstanding good points / issues for that execution alone (up to 1-2 each, with details referred from the original retrospective or summary)
- A link (relative path) to that execution's retrospective or summary, when one is retained

**The purpose is overview by aggregation**; do not transcribe the underlying retrospective or summary verbatim (the original artifact is the primary source). Write the aggregation paragraphs from the perspective of communicating to the reader "how this execution functioned within the overall flow of the roadmap".

### Roadmap-specific improvement proposals

Write only improvement proposals at the roadmap layer. Improvement proposals concluded inside underlying workflow-level executions are already owned by those executions, so write here only what is integrated/abstracted to the strategic level.

#### Aspects that should be included

- **Roadmap CLI progress model proposals**: whether additions are needed for the `events` array / `last_step` field / status_view derived view / ms-precision timestamps that are scoped out in this version
- **Reflection on milestone splitting granularity**: validity of 1:N executions, accuracy of anticipated execution count estimates, milestones that needed re-decomposition
- **Necessity of finer-grained execution reflection**: through actual operation, whether the roadmap needs additional progress signals from workflow-level executions
- **`roadmap` ↔ workflow-level execution integration protocol**: whether bidirectional ID references and the writer asymmetry (workflow execution → roadmap is the norm) functioned operationally without issue

Each improvement proposal is decomposed to action granularity: not "improve X" but "when X happens, do Y".

### Hand-off to the next cycle

Describe knowledge usable when starting the next similar roadmap, reusable milestone patterns, and pitfalls to avoid. Since this section becomes **the largest transmission channel to other roadmaps**, write it in a generalized form (avoid or abstract proper nouns specific to this roadmap).

### Reflection on user approval gates

`roadmap` has 3 user approval gates (Step 1: Roadmap Intent / Step 2: Milestone Decomposition / Step 4: Roadmap Retrospective). Record the history of approvals / rejections / change requests at each gate, and reflect on the cause of any rejections.

### Cost / time

- Days elapsed across the entire roadmap (Step 1 start through Step 4 completion)
- Number of underlying workflow-level executions (total of `workflow_identifiers[]`)
- Effective parallelism (peak number of concurrently in-progress underlying executions)
- Launch counts of roadmap-system Specialists (`roadmap-analyst` / `roadmap-planner` / `roadmap-retrospective-writer`)

## Quality criteria

Use the roadmap-specific quality criteria below:

| Good                                                                                                                        | Bad                                                                             |
| --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **All** underlying workflow-level retrospectives or summaries are summarized as aggregation paragraphs                      | Some execution's retrospective or summary is not mentioned                      |
| The milestone achievement overview table matches `progress.yaml.milestones[]`                                               | The table is stale, or has notation drift from the yaml                         |
| Dependency graph validity is written from the 4 aspects "as intended" / "unnecessary" / "missing" / "effective parallelism" | Ends with abstract impressions like "the dependency graph generally functioned" |
| Improvement proposals are purified to the roadmap layer (strategic level)                                                   | Tactically duplicates improvement proposals from inside underlying executions   |
| The judgment process is written for milestones ending in `cancelled` / `blocked`                                            | Unmet milestones are not mentioned, or the basis is unclear                     |
| The file location follows `docs/retrospective/roadmap-<roadmap-id>.md`                                                      | The `roadmap-` prefix is missing, or the directory is wrong                     |
| Causal analysis is done from observed data (`progress.yaml` timestamps and workflow_identifiers)                            | Ends with impressions / opinions                                                |

## Data sources (required as input)

- `docs/roadmap/<roadmap-id>/roadmap.md` (purpose / scope / dependency graph)
- All `docs/roadmap/<roadmap-id>/milestones/<milestone-id>.md` (each milestone definition / goals)
- `docs/roadmap/<roadmap-id>/progress.yaml` (final state, timestamps, list of workflow_identifiers)
- Retrospectives or summaries of each underlying workflow-level execution (aggregation target)
- Any retained delegated execution artifacts or summaries linked from milestone notes (when tracing detailed progress)

## Related artifacts

- **Inputs:** all roadmap artifacts (`roadmap.md` / `milestones/*.md` / `progress.yaml`) + all retrospectives or summaries of the underlying workflow-level executions
- **Output destination:** `docs/retrospective/roadmap-<roadmap-id>.md` (persisted in the repository. Deletable once improvement items are consumed at the start of the next roadmap)
- **Reflection destinations:** improvement proposals directly feed into the next roadmap's `roadmap.md` / updates to the `roadmap` plugin / `progress.yaml` schema extensions
- **Related:** `references/roadmap.md`, `references/milestone.md`
