---
name: roadmap
description: >
  [Main / Strategic layer] Top-tier entry point for multi-cycle development that exceeds the
  scope of a single oh-my-codingagent execution cycle. Bundles multiple oh-my-codingagent execution cycles into a single
  roadmap by (i) verbalising the roadmap's worldview and scope, (ii) decomposing it into
  observable milestones, and (iii) delegating execution of each milestone to user-launched
  oh-my-codingagent execution cycles. Main runs all four roadmap steps (Roadmap Intent / Milestone
  Decomposition / Execution / Roadmap Retrospective) directly; no roadmap-side specialist
  exists. The Execution step is an observer marker — `roadmap` never auto-launches
  oh-my-codingagent execution cycles (asymmetric coupling).
  Activation triggers: "create a roadmap", "plan multi-cycle development", "set up a
  strategic roadmap", "start roadmap", "milestone decomposition".
  Do NOT use for: tactical implementation workflow (delegate to oh-my-codingagent),
  per-step procedure detail (use `roadmap-*`), artifact format reference only (use
  `share-artifacts`), auto-launching oh-my-codingagent execution cycles (the rule is asymmetric coupling
  — Main only invites the user to launch the next cycle), roadmap-of-roadmaps (out of
  scope; nesting beyond one level not supported), CI / external system integration,
  step-level progress reporting (future extension).
---

# roadmap — Multi-Cycle Strategic Roadmap Layer

Use case category: **Workflow Automation**
Design pattern: **Sequential Workflow** + **Multi-Service Coordination** (strategic layer
loosely binding tactical-layer oh-my-codingagent execution cycles).

This skill is the **strategic layer** of the `totto2727-dev-flow` plugin. Where a single
oh-my-codingagent execution cycle handles "what to build and how" inside roughly one PR-sized increment,
`roadmap` plans and tracks **multi-cycle efforts**: it (i) verbalises the worldview and
scope of the whole roadmap, (ii) decomposes it into observable milestones, and (iii) closes
out the roadmap by aggregating per-cycle retrospectives. `roadmap` tracks high-level milestones, while oh-my-codingagent owns tactical execution cycles referenced from milestone notes or workflow identifier fields.

## Roadmap-specific principles

`roadmap` keeps only strategic governance rules:

- `progress.yaml` is the single source of roadmap progress and is changed through the roadmap CLI.
- `roadmap.md`, `milestones/`, and `adr/` are the durable planning surface.
- Milestones may reference tactical execution cycles, but `roadmap` does not launch or manage those cycles.
- Tactical workflow, PR handling, CI handling, and specialist routing belong to oh-my-codingagent.
- Project-level rules and repository conventions override this plugin when they are more specific.

## Role definitions

### Main (= roadmap orchestrator)

**Responsibilities:**

- Direct dialogue with the user (Roadmap Intent eliciting, milestone-decomposition
  alignment, retrospective presentation).
- Roadmap-wide progress management (current step, gate, Blockers, awareness of running
  downstream oh-my-codingagent execution cycles).
- Performing each step directly (all four roadmap steps are Main-only).
- Exit-Criteria evaluation per step.
- Constructing user-approval gate materials (the artifact itself, per
  Artifact-as-Gate-Review).
- **Awareness of running cycles in Step 3**: while the downstream cycles run autonomously,
  Main observes their progress through `progress.yaml`.

**Principles:**

- Main does not perform implementation work directly (it focuses on dialogue,
  judgment, and assignment).
- **Main never auto-launches oh-my-codingagent execution cycles**. The user manually starts each
  cycle; Main only invites the user to do so for the next milestone.

### No Specialist tier

`roadmap` has **no specialist subagents**. All four roadmap steps are Main-only:

- **Step 1, 2, 4** are dialogue / aggregation work where context-isolation, parallelism,
  and independent-viewpoint justifications do not apply. The full procedure lives in
  `roadmap-intent`, `roadmap-decomposition`, and `roadmap-retrospective`.
- **Step 3 (Execution)** has no specialist by construction: the user manually launches
  oh-my-codingagent execution cycles, each cycle autonomously updates `progress.yaml`, and
  Main observes. Step 3 is captured **inline** in this SKILL because there is no
  procedure substantial enough to extract into a `step-*`.

---

## Roadmap diagram

```mermaid
graph LR
    S1[Step 1<br/>Roadmap Intent]
    S2[Step 2<br/>Milestone Decomposition]
    S3[Step 3<br/>Execution &mdash; observer]
    S4[Step 4<br/>Roadmap Retrospective]
    DONE([Roadmap completed])
    DW{{User-launched oh-my-codingagent execution cycles<br/>each cycle autonomously updates<br/>progress.yaml}}

    S1 -->|Gate: User approval| S2
    S2 -->|Gate: User approval<br/>= execution-start agreement| S3
    S3 -->|Gate: Main judgment<br/>all milestones completed| S4
    S4 -->|Gate: Main judgment| DONE
    DW -.->|state updates| S3
```

## Step list

| Step | Title                   | Invocation           | Gate          | Detail SKILL               |
| ---- | ----------------------- | -------------------- | ------------- | -------------------------- |
| 1    | Roadmap Intent          | Main only            | User approval | `roadmap-intent`           |
| 2    | Milestone Decomposition | Main only            | User approval | `roadmap-decomposition`    |
| 3    | Execution               | Main only (observer) | Main judgment | inline (this SKILL, below) |
| 4    | Roadmap Retrospective   | Main only            | Main judgment | `roadmap-retrospective`    |

Per-step exit criteria, rollback specifics, and commit examples live in the corresponding
`roadmap-*/SKILL.md` (or, for Step 3, in the inline section below).

---

## Step 3: Execution (inline)

Step 3 is a **marker step** with no specialist and no separate procedure document. It
spans the period during which the user manually launches oh-my-codingagent execution cycles for each
milestone, and each cycle autonomously updates `progress.yaml`.

### What Main watches

Main reads `docs/roadmap/<roadmap-id>/progress.yaml` periodically and on user
request, looking at:

- `milestones[].status` transitions:
  - `planned → active` when the corresponding oh-my-codingagent execution cycle starts.
  - `active → completed` when the cycle's Step 9 (Retrospective) completes.
  - `blocked` if the downstream cycle reports a long-running Blocker.
- `milestones[].workflow_identifiers[]`: the list of cycle `<identifier>` values bound
  to each milestone (1:N is allowed; multiple cycles may attach to the same milestone).
- The roadmap-wide `status` (stays `active` throughout Step 3).

### Main's actions during Step 3

1. After Step 2 completes, present the next milestone to the user and obtain agreement
   to launch the corresponding oh-my-codingagent execution cycle. Remind the user to pass
   `<roadmap-id>` and `<milestone-id>` when starting the cycle.
2. **Do not launch `totto2727-dev-flow` from `roadmap`** (asymmetric coupling rule). The
   user runs `totto2727-dev-flow`; Main observes.
3. When the user asks for a progress check, summarise the current
   `progress.yaml` view (per-milestone status, attached identifiers, any
   `blocked` milestones).
4. If a milestone stays `blocked` for an extended period, raise an
   In-Progress user inquiry to choose between cancel / re-decompose (back to Step 2) /
   Intent revision (back to Step 1).

### When to advance to Step 4

When all entries in `milestones[]` are `completed` or `cancelled`, present to the user
the readiness to start Step 4 and proceed to `roadmap-retrospective`. The roadmap
`status` remains `active` until the Step 4 commit transitions it to `completed`.

### Exit criteria (Step 3)

- All `milestones[]` are `completed` or `cancelled`.
- For parallel milestones (1:N), the user has agreed to the final-state rule (e.g. "all
  N cycles complete → `completed`" vs. "first cycle complete → `completed`"); typically
  finalised in Step 4.
- The roadmap-wide `status` is still `active` (transitions to `completed` only at Step
  4 completion).

### Step 3 has no commit of its own

Downstream cycles commit per their own conventions; Step 3 in `roadmap` does not
produce its own commit (apart from any Roadmap mode ADR Main may file mid-execution if
a long-lived shared norm surfaces — those follow `share-adr/SKILL.md`).

---

## Connection protocol with `totto2727-dev-flow`

`roadmap` and `totto2727-dev-flow` are connected via a bidirectional ID reference. The
full update protocol (write order, retry, conflict resolution) lives in
`totto2727-dev-flow/SKILL.md` ("`progress.yaml` update protocol"). This section
summarises the surface that the roadmap side sees.

### Bidirectional reference

```mermaid
graph LR
    subgraph RP[docs/roadmap/&lt;roadmap-id&gt;/progress.yaml]
        M1[milestones&#91;&#93;.id]
        M2["milestones&#91;&#93;.workflow_identifiers&#91;&#93;<br/>= &#91;identifier-A, identifier-B, ...&#93;"]
    end
    subgraph PG[docs/workflow/&lt;identifier&gt;/progress.yaml]
        R1[roadmap.id = &lt;roadmap-id&gt;]
        R2[roadmap.milestone.id = &lt;milestone-id&gt;]
    end

    M2 -->|forward reference| PG
    R1 -.->|back reference| RP
```

- **roadmap → workflow**: `progress.yaml.milestones[].workflow_identifiers[]`
  holds attached `<identifier>` values (1:N). Detailed progress is fetched from the
  workflow side on demand (minimal-scope principle).
- **workflow → roadmap**: `progress.yaml.roadmap = {id: <roadmap-id>, milestone: {id:
<milestone-id>}}` or `null`. Non-null means the cycle must update the corresponding
  `milestones[]` entry on cycle start and on cycle end.

### Who writes what, when (summary)

| Trigger                                                                             | Owner                          | Effect on `progress.yaml`                                                       |
| ----------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------- |
| `roadmap` Step 1 completes                                                          | `roadmap-intent` (Main)        | Initialise `roadmap_id` / `title` / `status: planned` / empty `milestones: []`. |
| `roadmap` Step 2 completes                                                          | `roadmap-decomposition` (Main) | Finalise `milestones[]` (`planned`); transition roadmap `status` to `active`.   |
| oh-my-codingagent execution cycle starts (during Roadmap Step 3)                    | `totto2727-dev-flow` Main      | `milestones[].status: planned → active`; append to `workflow_identifiers[]`.    |
| oh-my-codingagent execution cycle completes (= cycle's Step 9 Retrospective commit) | `totto2727-dev-flow` Main      | `milestones[].status: active → completed`.                                      |
| `roadmap` Step 4 completes                                                          | `roadmap-retrospective` (Main) | Roadmap `status: active → completed`.                                           |

### Concurrency notes

- The two write triggers from the workflow side ("cycle start" and "cycle end") are
  rare events, so contention is unlikely.
- Residual rare conflicts are caught by the YAML-syntax `pre-commit` hook.
- On conflict, neither the workflow Main nor a specialist resolves it unilaterally;
  it is reported as a Blocker (`specialist-common §4` Case B), and the roadmap Main
  drives recovery.
- Detailed recovery uses the roadmap CLI as the single writer for `progress.yaml`; do not
  edit the YAML through share-artifacts templates.

---

## Session resume preamble

Detailed per-step resume actions live in the corresponding `roadmap-*` SKILL
(Step 3 actions are inline above). This preamble defines the cross-step shared
preparation.

The `totto2727-dev-flow` resume principles (specialist non-reuse across sessions,
artifact-based context restoration) are inherited. Roadmap-specific additions:

1. **Read the source of truth**: `docs/roadmap/<roadmap-id>/progress.yaml`.
2. **Read all existing artifacts**: `roadmap.md` and every
   `milestones/<milestone-id>.md`.
3. **Two-tier state check**: roadmap-wide `status` + each `milestones[].status` + the
   attached `<identifier>` values in `workflow_identifiers[]`.
4. **Execution-side resume takes priority**: if any milestone is `active`, scan the
   bound `<identifier>`s or milestone notes and let oh-my-codingagent restore tactical
   execution state first. The roadmap resume waits until execution-side consistency is restored.
5. **Refresh `updated_at` and commit a resume marker**:
   `docs(roadmap/<roadmap-id>): resume session`.

### Resume scenarios

| Scenario                                 | State                                                                                                 | Path forward                                                                                                                                            |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A: Step 1–2 done, Step 3 not started** | Roadmap `status: active` / all `milestones[].status: planned` / `workflow_identifiers[]` empty        | Present the next milestone to the user; invite the user to launch the corresponding oh-my-codingagent execution cycle. (See "Step 3: Execution" above.) |
| **B: Step 3 in progress**                | Roadmap `status: active` / one or more `milestones[].status: active` with running `<identifier>`s     | Run execution-side session resume first (preamble item 4). Present a milestone-progress summary and confirm next-launch agreement with the user.        |
| **C: Step 4 in progress**                | Roadmap `status: active` / all `milestones[]` are `completed` or `cancelled` / Step 4 already started | Continue per `roadmap-retrospective`.                                                                                                                   |

### Detecting resumable roadmaps

When the user activates `roadmap`, before starting a new roadmap Main scans
`docs/roadmap/` for resumable roadmaps:

1. Detect `docs/roadmap/<roadmap-id>/progress.yaml` files where `status !=
completed`.
2. If any are found, ask the user whether to resume one or to start fresh.
3. On resume, follow the preamble above and the relevant scenario.
4. On a fresh start, agree on a new `<roadmap-id>` and proceed to
   `roadmap-intent`.

---

## Project-rule precedence

`roadmap` inherits the `totto2727-dev-flow` policy: **the overall process structure
(steps, artifact formats, gate decisions) follows this skill, while implementation
patterns / test rules / commit conventions / naming conventions / platform-specific
commands defer to project-specific skills** (`coding`, `git-workflow`,
`macos-cli-rules`, etc.). See `totto2727-dev-flow/SKILL.md` "Relationship with project-specific
rules" for the canonical statement.

Roadmap-specific notes:

- Milestone-granularity decisions interact with project implementation and test
  conventions. Step 2 (`roadmap-decomposition`) requires Main to load the
  relevant project-specific skills.
- Roadmap-wide constraints (parallel-execution allowance, release-freeze windows,
  etc.) follow project operational rules. Main confirms them with the user during
  Step 1 (`roadmap-intent`) and records them in `roadmap.md`'s Intent section.

---

## What this skill does NOT cover

- **Per-step exit criteria, rollback details, and commit examples** → see the
  corresponding `roadmap-*/SKILL.md` (or, for Step 3, the inline section above).
- **Per-cycle implementation, design, and validation** → fully delegated to downstream
  oh-my-codingagent execution cycles. The roadmap layer is purely strategic.
- **Auto-launching of oh-my-codingagent execution cycles** → forbidden (asymmetric coupling).
- **Roadmap-of-roadmaps** (more than one nesting level) → out of scope for this version.
- **CI / external system integration with `progress.yaml`** → out of scope; the
  YAML is machine-readable but no GitHub Actions / webhook integration is provided here.
- **Step-level progress reporting** (per-step granularity) → out of scope (future
  extension). Use `workflow_identifiers[]` or milestone notes to hand off to
  oh-my-codingagent when finer detail is needed.
- **`events[]` / `status_view` derived views / millisecond-precision timestamps** → out
  of scope (future extension).
- **Artifact format / template specifications** → see `share-artifacts`
  (`references/roadmap*.md`, `templates/roadmap*.md`, `templates/milestone.md`).
- **ADR conventions and the General mode / Roadmap mode split** → see `share-adr`.
- **Single-cycle development** → use oh-my-codingagent directly. This skill is for
  multi-cycle scope only.
- **PR / CI command details** → delegated to oh-my-codingagent. `roadmap` itself does
  not orchestrate PR / CI; downstream execution cycles do.
