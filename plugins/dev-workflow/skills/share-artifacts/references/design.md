# Reference: How to write `design.md`

## Purpose

Before implementation, organize the **architecture, component composition, API design, data flow, and alternatives**. Write to a level of detail at which the implementer during Steps 6-7 can make implementation decisions from this document alone. Cycle-specific decisions are concluded here (only project-wide decisions are filed separately as ADRs).

## Author / creation timing

- **Author:** `architect` Specialist (single instance, iterative refinement)
- **Step:** Step 3 (Design)
- **Approval:** user approval required (Artifact-as-Gate-Review)

## File location

`docs/workflow/<identifier>/design.md`

## How to write each section

### Design goals and constraints

Begin the document with a **quotation** from `intent-spec.md`. Make the purpose, success criteria, and main constraints explicit as the starting point for design decisions.

### Approach overview

State the overall picture in **1-3 paragraphs**. Details are expanded in the component composition and later sections. Always include the central reason "why this approach".

### Component composition

- A list of the main components / modules / layers and their roles
- Visualizing relationships with a Mermaid diagram is recommended
- Make the boundaries and connection points with existing components explicit

### Main types and interfaces

Write to the **concrete level that is implementable**. Express them with type definitions in TypeScript / Rust / Go etc. If the API contract can be expressed with types, do so actively.

### Data flow / API design

Describe an API endpoint table:

| Method | Path | Description | Request | Response |
| ------ | ---- | ----------- | ------- | -------- |

Express the data flow with a diagram (sequence diagram, etc.).

### Alternatives and rationale

**Always compare 2-3 alternatives.** A design document with only one option indicates shallow consideration.

| Option | Overview | Adopted / Rejected | Reason |
| ------ | -------- | ------------------ | ------ |
| A      | ...      | Adopted            | ...    |
| B      | ...      | Rejected           | ...    |

### Anticipated extension points

Make explicit the extension room reserved by this design for future expansion. Within reason of the YAGNI principle.

### Operational considerations

Describe all of the following (mark "N/A" explicitly if not applicable):

- Monitoring / observation
- Migration / cutover
- Rollout
- Rollback
- Security
- Performance projection

### References to ADRs that cross cycle boundaries

Only when a decision **with effect beyond the current cycle** occurs in this cycle, link to the ADR. The `share-adr` skill has 2 modes with different storage destinations:

- **General mode (`docs/adr/`)**: decisions affecting multiple roadmaps / multiple independent dev-workflow cycles / the whole project
- **Roadmap mode (`docs/roadmap/<roadmap-id>/adr/`)**: decisions shared by multiple cycles under a single roadmap (only an option when the current cycle is launched under a roadmap)

For details of mode determination, see "Mode determination flow" in `share-adr/SKILL.md`.

### Hand-off points to Task Decomposition

Hints used by Step 5's `planner`. Make explicit the granularity targets for task splitting and clues for parallelism.

## Quality criteria

| Good                                                     | Bad                                       |
| -------------------------------------------------------- | ----------------------------------------- |
| The implementer can make implementation decisions from this design alone | Abstract and not actionable for implementation |
| 2-3 alternatives are compared                            | Only the adopted option is described      |
| All categories of operational considerations are filled  | Security and performance are missing      |
| Implications of Research Notes are reflected in design decisions | The investigation is ignored in the design |

## ADR filing decision criteria

Determining whether to conclude inside `design.md` or file an ADR separately:

| Subject of an ADR (filed via the `share-adr` skill)                                          | Not subject to an ADR (concluded inside `design.md`) |
| --------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| Adopting Effect across the entire project (General)                                           | The cache strategy of this feature is LRU            |
| Using gRPC across all services (General)                                                      | Pagination of this API is cursor-based               |
| Unifying the authorization layer with OpenFGA (General)                                       | Validation of this screen is written with zod        |
| Conventions shared by multiple independent dev-workflow cycles (General)                      | Naming rules for temporary KV keys in this cycle     |
| `AuthSession` type definition shared by all cycles under the `oauth-rollout` roadmap (Roadmap)| Wording of the Session guard in this cycle           |

- Affects other features / other teams / future cycles → ADR
- Concluded within this cycle → keep inside `design.md`
- When filing an ADR, additionally perform **mode determination**: choose General / Roadmap depending on whether it is closed inside a single roadmap or spans multiple, following "Mode determination flow" in `share-adr/SKILL.md`

## Related artifacts

- **Inputs:** `intent-spec.md` and all `research/*.md`
- **Output destinations:** `task-plan.md` (planner) and all artifacts from Step 6 onward
- **ADR linkage:** if filed, recorded in `progress.yaml.artifacts.external_adrs` (both General / Roadmap mode listed at the same level), with a link from `design.md`
