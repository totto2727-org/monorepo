# Sample resource contract

## Role

A document `sample.md` is a reproducible concrete rendered output of its sibling template. It demonstrates the specification in a reviewable form; it is not an external-link stub or an independently authored alternative.

## Vertical slice invariant

Every document slice has exactly `{document}/spec.md`, `{document}/template.md`, and `{document}/sample.md`: the specification constrains semantics, the template constrains the minimum rendered form while allowing justified extensions, and the sample is a reproducible concrete output of the sibling template. Internal maintenance areas are intentionally asymmetric: `internal/spec/` contains its common specification template, while this directory and `internal/template/` contain only `spec.md` because concrete samples and templates vary by document kind. An internal `sample.md` or a meta-template under `internal/sample/` or `internal/template/` is prohibited; use the `readme/`, `agents/`, and `adr/` slices as concrete examples.

## Required content

A sample contains only the rendered document content. Maintain a named validation fixture that records the document type, sibling specification and template paths, render context, provenance checks, and validation checks. Preserve the exact result of rendering the sibling template, except for final-newline normalization when the validation explicitly permits it; do not wrap it in a shared sample-record structure.

## Naming and path

Name the resource `sample.md` and store it beside the matching `spec.md` and `template.md` in a document slice. Never add an internal sample or sample meta-template; the README, AGENTS, and ADR document slices are the only concrete examples for the internal contracts.

## Consistency and extension

Keep the sample consistent with the sibling specification and byte-reproducible from the sibling template and recorded fixture context. A justified extension is allowed only when it is present in both the rendered sample and its reproducible fixture and does not remove mandatory form.

## Validation

Render the sibling template with the recorded context under Jinja `StrictUndefined`, compare the result to the sample, and verify every provenance link and path. Reject samples whose validation fixture cannot reproduce them or identify its fixture, and reject raw links substituted for concrete rendered content.
