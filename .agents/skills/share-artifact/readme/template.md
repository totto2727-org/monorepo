{# Extensions may add end-user sections if they preserve this order, keep License last, retain the MoonBit canonical-output and relative-symlink rule when applicable, and do not add developer, contributor, AI, or internal-operation guidance. -#}

# {{ project_name }}

{# State the end-user outcome, not the repository implementation. -#}
{{ overview }}

{% if is_moonbit -%}
This document is canonical `README.mbt.md`; maintain `README.md` as the relative symlink `README.md -> README.mbt.md`.
{%- endif %}

## Usage

{# Imports and dependency declarations belong in Setup. Select exactly one surface: library, cli, or gui. -#}
{% if usage_surface == "library" -%}
{% if usage_examples -%}
{% for example in usage_examples -%}

```{{ example.language }}
{{ example.code }}
```

{% endfor -%}
{% else -%}
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

{# Steps acquire/install the consumer artifact and declare its imports or aliases; repository preparation belongs in AGENTS.md. -#}
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

## Development

{{ development_summary }}

## License

{{ license }}

_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._
