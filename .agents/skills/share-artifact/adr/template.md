{# Extensions may add purpose-specific sections only if they preserve every required section and comply with ADR scope, storage, confirmation, and immutability rules. A confirmed ADR body is immutable; supersede it with a new ADR instead. -#}

{{ "---" }}
confirmed: {{ confirmed | lower }}
scope: general
---

# ADR: {{ title }}

- **Filed at:** {{ filed_at }}
- **Decision owner:** {{ decision_owner }}
- **Origin:** {{ origin }}
- **Storage path:** {{ storage_path }}

## Context

{{ context }}

## Decision

{{ decision }}

<!-- prettier-ignore-start -->

| Option | Summary | Result | Rationale |
| --- | --- | --- | --- |
{% for option in options -%}
| {{ option.name }} | {{ option.summary }} | {{ option.result }} | {{ option.rationale }} |
{% endfor -%}
{{ "\n" -}}

<!-- prettier-ignore-end -->

## Consequences

- **Added:** {{ consequences.added }}
- **Existing impact:** {{ consequences.existing_impact }}
- **Future constraints:** {{ consequences.future_constraints }}
- **Costs and limitations:** {{ consequences.costs_and_limitations }}

{% if related_records -%}

## Related records

{% for record in related_records -%}

- [{{ record.title }}]({{ record.path }})

{% endfor -%}
{% endif -%}

_This ADR was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [ADR template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/adr/template.md)._
{%- if superseded_by -%}
{{ "\n\n" -}}

> Superseded by [{{ superseded_by.title }}]({{ superseded_by.path }})

{%- endif %}
