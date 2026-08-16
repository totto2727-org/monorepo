# Template resource contract

## Role

A document `template.md` constrains the minimum rendered form of its document kind. It is a valid Jinja Markdown maintenance template that makes mandatory context and sections explicit without becoming a runtime dependency.

## Vertical slice invariant

Every document slice has exactly `{document}/spec.md`, `{document}/template.md`, and `{document}/sample.md`: the specification constrains semantics, the template constrains the minimum rendered form while allowing justified extensions, and the sample is a reproducible concrete output of the sibling template. Internal maintenance areas are intentionally asymmetric: `internal/spec/` contains its common specification template, while this directory and `internal/sample/` contain only `spec.md` because concrete templates and samples vary by document kind. An internal `sample.md` or a meta-template under `internal/template/` or `internal/sample/` is prohibited; use the `readme/`, `agents/`, and `adr/` slices as concrete examples.

## Required content

Declare every required render context, render every required section in the required order, guard only optional sections, and include any required provenance or operational instructions from the sibling specification. Use standard Jinja delimiters and Markdown that remains useful after rendering. Do not impose shared headings or layout across document kinds.

## Naming and path

Name the resource `template.md` and store it beside the matching `spec.md` and `sample.md` in a document slice. Do not add an internal template meta-template, renderer, generated script, or parallel template format.

## Consistency and extension

The template must implement the sibling specification's mandatory form, and the sample must be reproducible from it. Authors may add justified purpose-specific sections only when they retain all required sections and do not violate audience, storage, symlink, or ADR immutability rules.

## Validation

Parse and render with Jinja `StrictUndefined` and `keep_trailing_newline=True`, using every required context. Confirm a removed required key raises `UndefinedError`, optional empty values do not render `None`, and the rendered result satisfies the sibling specification. Reject malformed Jinja, silent defaults for required values, and an internal `sample.md`.
