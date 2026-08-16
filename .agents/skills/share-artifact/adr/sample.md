---
confirmed: false
scope: general
---

# ADR: adopt-versioned-api

- **Filed at:** 2026-08-12
- **Decision owner:** Platform maintainers
- **Origin:** API compatibility review
- **Storage path:** docs/adr/2026-08-12-adopt-versioned-api.md

## Context

Independent clients need a durable compatibility policy across releases.

## Decision

Adopt explicit versioned API paths for published endpoints.

<!-- prettier-ignore-start -->

| Option | Summary | Result | Rationale |
| --- | --- | --- | --- |
| Versioned paths | Publish a version in each stable path. | Adopted | Makes compatibility boundaries explicit. |
| Unversioned paths | Change one shared path in place. | Rejected | Breaks independent clients without an explicit migration boundary. |

<!-- prettier-ignore-end -->

## Consequences

- **Added:** A version segment and compatibility policy.
- **Existing impact:** Existing clients migrate on their supported schedule.
- **Future constraints:** Breaking changes require a new version.
- **Costs and limitations:** Parallel version maintenance increases review work.

## Related records

- [API migration design](../design/api-migration.md)

_This ADR was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [ADR template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/adr/template.md)._
