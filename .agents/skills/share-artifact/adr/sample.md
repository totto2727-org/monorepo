---
confirmed: false
scope: general
---

<!-- Illustrative decision record for a hypothetical API project. -->

# ADR: adopt-versioned-api

- **Filed at:** 2026-08-12
- **Decision owner:** Platform maintainers
- **Origin:** API compatibility review

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
