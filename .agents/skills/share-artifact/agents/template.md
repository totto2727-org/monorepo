{# Illustrative shape only: retain useful repository-specific instructions, not empty sections. #}
# {{ project_name }}

## Repository structure

{{ repository_structure }}

## Development commands

### Execution rules

{{ command_location_and_environment }}

### Standard tasks

{% for task in tasks %}
- `{{ task.command }}`: {{ task.purpose }}
{% endfor %}

## Architecture

{{ architecture_constraints }}

## Development tools

{{ tool_specific_notes }}

## Package-specific rules

{{ package_rules }}

## Task-specific documentation

{% for link in documentation_links %}
- When {{ link.task }}: [{{ link.title }}]({{ link.path }}).
{% endfor %}

{# Include when the repository uses the MoonBit physical README convention. #}
{% if moonbit_readme %}
## MoonBit README maintenance

Keep consumer content in the physical `README.mbt.md` file with the relative symlink `README.md -> README.mbt.md`.
Check supported executable examples against the actual package with `moon check README.mbt.md` and `moon test README.mbt.md`.
{% endif %}
