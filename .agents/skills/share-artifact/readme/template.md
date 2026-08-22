{# Organize content around user value, not implementation or generated-artifact maintenance. Extensions may add end-user sections if they preserve this order, keep License last, and do not add developer, contributor, AI, or internal-operation guidance. -#}

# {{ project_name }}

{# State the end-user outcome, not the repository implementation. -#}
{{ overview }}

{# Use root for the repository consumer entrypoint, independent only for a genuinely separate consumer entrypoint, and nested for a compact non-duplicating package or directory entry. -#}
{% if entry_scope == "root" or entry_scope == "independent" -%}

## Usage

{# Show a plausible goal, representative input, primary public operation, and user-relevant outcome. Imports, constructors, initialization, ID round trips, and default-field inspection alone do not qualify. Select exactly one surface: library, cli, agent, or gui. -#}
{% if usage_surface == "library" -%}
{% if usage_examples -%}
{% for example in usage_examples -%}
{{ example.summary }}

```{{ example.language }}
{{ example.code }}
```

{% endfor -%}
{% else -%}
{# Link directly to a concrete runnable example; for interface-only libraries, the linked implementation Usage must demonstrate real integration. -#}
{{ usage_guide.summary }}

See [{{ usage_guide.title }}]({{ usage_guide.path }}).
{% endif -%}
{% elif usage_surface == "cli" -%}
{% if cli_usage_examples -%}
{% for example in cli_usage_examples -%}
{{ example.summary }}

```bash
{{ example.command }}
```

Expected result:

```text
{{ example.result }}
```

{% endfor -%}
{% else -%}
{{ [] | first }}
{% endif -%}
{% elif usage_surface == "agent" -%}
{% if agent_usage_examples -%}
{% for example in agent_usage_examples -%}
{{ example.summary }}

```text
{{ example.prompt }}
```

Expected result:

```text
{{ example.result }}
```

{% endfor -%}
{% else -%}
{{ [] | first }}
{% endif -%}
{% elif usage_surface == "gui" -%}
![{{ gui_usage.image_alt }}]({{ gui_usage.image_path }})

{{ gui_usage.interaction_result }}
{% else -%}
{{ [] | first }}
{% endif -%}

## Key features

{% for feature in features -%}

- {{ feature }}

{% endfor -%}

## Prerequisites

{# Include only consumer requirements that must be satisfied before setup. Put constraints and error behavior in Usage, API, or a purpose-specific end-user section. -#}
{% if prerequisites -%}
{% for prerequisite in prerequisites -%}

- **{{ prerequisite.name }}**: {{ prerequisite.detail }}

{% endfor -%}
{% else -%}
No prerequisites.
{% endif -%}

## Setup

{# Steps only acquire/install the consumer artifact or declare dependencies, imports, and aliases. Execution, verification, and authentication belong in Usage or another end-user section; repository build/test/operations belong in AGENTS.md. -#}
{% if setup_steps -%}
{% for step in setup_steps -%}
{{ loop.index }}. {{ step.description }}

```{{ step.language }}
{{ step.command }}
```

{% endfor -%}
{% else -%}
No setup is required.
{% endif -%}
{% elif entry_scope == "nested" -%}
{% if usage_guide -%}

## Usage

{{ usage_guide.summary }}

See [{{ usage_guide.title }}]({{ usage_guide.path }}).
{% endif %}
{% else -%}
{{ [] | first }}
{% endif -%}

## API

{% if api.mode == "registry" -%}
[{{ api.registry_name }} API reference]({{ api.registry_url }})
{% elif api.mode == "inline" -%}
{% for entry in api.entries -%}

### `{{ entry.name }}`

{{ entry.summary }}

```{{ entry.language }}
{{ entry.example }}
```

{% endfor -%}
{% elif api.mode == "guide" -%}
{{ api.guide_summary }}

See [{{ api.guide_title }}]({{ api.guide_path }}).
{% else -%}
{{ [] | first }}
{% endif -%}

{% if entry_scope == "root" or entry_scope == "independent" -%}

## Development

{{ development_summary }}

## License

{{ license }}
{% endif %}
_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._
