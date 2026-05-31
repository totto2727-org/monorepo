# Reference: How to write `research/<topic>.md`

## Purpose

Focused on **a single research aspect**, organize **facts and design implications** of existing code, dependencies, external specifications, similar examples, etc., in a form usable by Step 3's `architect`. Do not stop at listing facts; the essence is showing "how this research result affects the design".

## Author / creation timing

- **Author:** `researcher` Specialist (launched in parallel as separate instances per aspect)
- **Step:** Step 2 (Research)
- **Approval:** Main verdict (user approval optional. In-progress inquiry only when there is a serious Blocker)

## File location

`docs/workflow/<identifier>/research/<topic>.md`

Examples of `<topic>`: `existing-impl` / `dependencies` / `similar-cases` / `external-spec` / `existing-adr` / project-specific

## How to write each section

### Subject of investigation

Make explicit **the scope this Research Note covers**. Clarify the boundary so it does not overlap with other Research Notes.

### Findings

Bullet list of facts. Write in **observable expressions**.

### Sources

**Always attach source references**. Without these, this becomes mere speculation.

| Good                                   | Bad           |
| -------------------------------------- | ------------- |
| `src/auth/login.ts:L42-L58`            | the auth code |
| ADR `docs/adr/2025-10-01-grpc.md`      | a past ADR    |
| [External Spec RFC 7519](https://...)  | the JWT spec  |
| catalog `api` in `pnpm-workspace.yaml` | dependencies  |

### Design implications

**The core of the Research Note.** Write how the facts affect design decisions.

- Good: "The existing `User` entity has `email` as nullable, so when adding authentication this time, validation design must assume nullable"
- Bad: "There was a `User` entity" (facts only, no implication)

Drill down to a granularity at which Step 3's `architect` can read this and use it directly for design decisions.

### Remaining unknowns

Points that could not be resolved by this investigation. Write as material for Main's judgment of which to recommend among launching an additional researcher / making an assumption in Design and proceeding / reporting as a Blocker.

## Quality criteria

| Good                                                        | Bad                                                 |
| ----------------------------------------------------------- | --------------------------------------------------- |
| All findings have a source (file:line / URL / ADR number)   | Hearsay style like "seems to be" or "appears to be" |
| Design implications descend to concrete recommended actions | Stops at listing facts                              |
| Covers only a single aspect                                 | Mixes multiple aspects in one file                  |
| Honestly states unknowns                                    | Vaguely glosses over insufficient research          |

## Related artifacts

- **Input:** `intent-spec.md` (premise and priority of investigation)
- **Output destination:** `design.md` (the architect integrates all Research Notes for design decisions)
- **Parallelism:** a separate researcher instance per aspect. Encroaching on other aspects is forbidden
