---
confirmed: false
scope: general
---

{# Illustrative decision record: adapt metadata and alternatives to the project's ADR convention. #}

# ADR: {{ title }}

- **Filed at:** {{ filed_at }}
- **Decision owner:** {{ decision_owner }}
- **Origin:** {{ origin }}

## Context

{{ problem_constraints_and_forces }}

## Decision

{{ chosen_approach_and_reason }}

## Alternatives

{{ alternatives_and_trade_offs }}

## Consequences

- **Added:** {{ additions }}
- **Existing impact:** {{ existing_impact }}
- **Future constraints:** {{ future_constraints }}
- **Costs and limitations:** {{ costs_and_limitations }}

{% if related_records %}

## Related records

{{ related_record_links }}

{% endif %}
