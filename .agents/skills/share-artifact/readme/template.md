{# Illustrative shape only: adapt or omit sections for the project and its consumers. #}
# {{ project_name }}

{{ overview }}

## Usage

{{ public_operation_and_result }}

## Key features

{% for feature in features %}
- {{ feature }}
{% endfor %}

## Prerequisites

{{ consumer_prerequisites }}

## Setup

{# Libraries can show dependency declarations and imports here. #}
{{ library_setup }}

{# For tools, keep only supported alternatives, not a sequence of required steps. #}
{% if temporary_setup %}
### Run without installing

{{ temporary_setup }}
{% endif %}

{% if persistent_setup %}
### Install

{{ persistent_setup }}
{% endif %}

{% if consumer_flake %}
### Nix flake

{{ consumer_flake }}
{% endif %}

## API

{{ public_reference_or_direct_link }}

## Development

For repository maintenance instructions, see [AGENTS.md]({{ agents_path }}).

## License

{{ license }}
