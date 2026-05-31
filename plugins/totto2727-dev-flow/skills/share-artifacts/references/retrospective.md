# Reference: How to write `retrospective.md`

## Purpose

Reflect on the entire cycle and extract **knowledge usable in subsequent cycles**. Not mere impressions, but causal analysis based on observed data (number of loops, Blocker history, approval gate history, count of temporary reports), and **actionable improvement proposals** are kept.

## Author / creation timing

- **Author:** `retrospective-writer` Specialist (single instance)
- **Step:** Step 9 (Retrospective)
- **Approval:** Main verdict (information sharing only with the user)

## File location

`docs/retrospective/<identifier>.md` (an aggregated directory in the same pattern as `docs/adr/`). The `<identifier>` is exactly the same as the cycle working directory `docs/workflow/<identifier>/`.

## Lifecycle

`retrospective.md` is **a volatile report box that is deleted once the next cycle has consumed its improvement items**. Decisions that should be persistently recorded are extracted into ADRs (`docs/adr/` or `docs/roadmap/<roadmap-id>/adr/`; mode determination in `share-adr/SKILL.md`) before deleting the retrospective.

| Kind          | Storage location                                | Lifecycle                                         |
| ------------- | ----------------------------------------------- | ------------------------------------------------- |
| ADR           | `docs/adr/` or `docs/roadmap/<roadmap-id>/adr/` | Persistent. Immutable once `confirmed: true`      |
| Retrospective | `docs/retrospective/`                           | Volatile. Deleted once consumed by the next cycle |

Deletion timing: at the point in the next cycle's Intent Spec when each improvement item is judged as "addressed / not needed / converted to ADR". The most recent 1-2 cycles' worth is left (since they have not yet become improvement candidates).

## How to write each section

### Cycle overview

In 1-3 paragraphs, what the cycle achieved against the purpose of the Intent Spec.

### What went well

Concretely describe **approaches that should be intentionally reproduced** in subsequent cycles.

- Good: "Launching the security aspect in parallel first in the Research Step made selecting the authorization model in the Design phase smoother"
- Bad: "Things went well"

### Issues

Causal analysis based on observed data:

#### Loop-count analysis

| Loop between steps | Count | Root cause         |
| ------------------ | ----- | ------------------ |
| Step 6 ↔ Step 7    | {{n}} | {{cause analysis}} |
| Step 6/7 → Step 3  | {{n}} | {{cause}}          |

#### Blocker history

For each Blocker, record the occurrence / resolution timestamps and the response.

### Improvement proposals for next time

Decompose to **concrete action granularity**. Not "improve X" but in the form "when X happens, do Y".

#### Process improvements

- Good: "When Intent Clarification reveals that a success criterion is unobservable, launch `validator` in advance for consultation"
- Bad: "Improve communication"

#### Skill improvements

Concrete improvement proposals for the totto2727-dev-flow plugin's skills (`totto2727-dev-flow` / `specialist-*` / `share-artifacts`).

- Target skill name
- Relevant section
- Concrete proposed change

#### Specialist prompt improvements

Proposals to be reflected in each Specialist's role definition / inputs / procedures.

### Reusable knowledge

Learnings that may help other cycles or other projects. Candidates to reflect into memory or CLAUDE.md.

### Reflection on user approval gates

A record of approvals / rejections at each approval gate. If there were rejections, reflect on the cause.

### Reflection on in-progress user inquiries

The count and main topics of `$TMPDIR/totto2727-dev-flow/*.md` temporary reports. A high count may indicate insufficient clarification at the Intent Spec stage.

### Cost / time

- Wall-clock time per phase
- Specialist launch counts
- Effective parallelism

## Quality criteria

| Good                                                                      | Bad                         |
| ------------------------------------------------------------------------- | --------------------------- |
| Causal analysis from observed data (loop counts / timestamps)             | Impressions / opinions      |
| Improvement proposals at action granularity (who / when / what does what) | Stops at "improve X"        |
| What went well is concrete and reproducible                               | Just "it was good"          |
| If a user approval was rejected, the cause is written                     | Rejections are not recorded |

## Data sources (required as input)

- All artifacts of the cycle
- `progress.yaml` (timestamps, completed_steps, user_approvals, rollbacks)
- `TODO.md` (re_activations, started_at / completed_at, External Review Round history)
- All `review/*.md` (6 aspects + project-specific additional aspects)
- `validation-report.md`
- List of `$TMPDIR/totto2727-dev-flow/*.md` temporary reports

## Related artifacts

- **Inputs:** all artifacts of the cycle + progress.yaml + TODO.md
- **Output destination:** persisted in the repository. Referenceable when the next cycle starts and from other projects
- **Reflection destinations:** improvement proposals directly feed the next cycle's Intent Spec / plugin updates
