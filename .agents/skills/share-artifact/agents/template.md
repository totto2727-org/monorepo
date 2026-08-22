{# Extensions may add repository-specific AI or developer sections if they preserve this order, retain the CLAUDE.md -> AGENTS.md relative-symlink alias, and do not become an end-user getting-started guide. -#}

# {{ project_name }}

## Repository structure

{{ repository_structure }}

## Development commands

### Execution rules

{% for rule in execution_rules -%}

- {{ rule }}

{% endfor -%}

### Standard tasks

{% for task in standard_tasks -%}

- `{{ task.command }}` — {{ task.description }}

{% endfor -%}

## Architecture

{% for section in architecture_sections -%}

### {{ section.title }}

{% for item in section['items'] -%}

- {{ item }}

{% endfor -%}
{% endfor -%}

## Development tools

{% for tool in development_tools -%}

- **{{ tool.name }}**: {{ tool.description }}

{% endfor -%}

{% if package_rules -%}

## Package-specific rules

{% for rule in package_rules -%}

- {{ rule }}

{% endfor -%}
{% endif -%}

{% if is_moonbit -%}

## MoonBit README maintenance

Keep the canonical end-user content in the physical `README.mbt.md` file and maintain `README.md` as the relative symlink `README.md -> README.mbt.md`. Validate supported MoonBit blocks with `moon check README.mbt.md` and `moon test README.mbt.md`. Never render canonical-file or symlink-maintenance instructions into the end-user README.
{% endif %}
_This AGENTS.md was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [AGENTS template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/agents/template.md)._
