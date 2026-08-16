# {{ resource_name }} resource specification

## Role

{{ purpose }}

## Scope

{{ scope }}

## Required content

{% for item in required_content %}

- {{ item }}
  {% endfor %}

## Naming and path

{{ path_rule }}

## Consistency obligations

{% for rule in consistency_rules %}

- {{ rule }}
  {% endfor %}

## Extension rule

{{ extension_rule }}

## Validation criteria

{% for check in validation_checks %}

- {{ check }}
  {% endfor %}
