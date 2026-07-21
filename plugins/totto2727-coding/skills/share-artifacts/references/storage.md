# Shared Artifact Storage

> Document type: concrete artifact storage policy.

## Roadmap artifacts

```text
docs/roadmap/<roadmap-id>/
|-- roadmap.md
|-- milestones/
|   `-- <milestone-id>.md
|-- adr/
|   `-- <YYYY-MM-DD>-<title>.md
`-- progress.yaml
```

`progress.yaml` is CLI-managed state, not a document template. Implementation-specific artifacts stay with their owning implementation effort and may be linked through `progress.yaml.milestones[].workflow_identifiers[]` when identifiers exist.

Choose a stable project-specific `<roadmap-id>`, such as a strategic objective, dated slug, or ticket ID. Avoid collisions with identifiers used by implementation efforts.

## Artifacts outside a roadmap directory

- General ADR: `docs/adr/<YYYY-MM-DD>-<title>.md`
- Roadmap retrospective: `docs/retrospective/roadmap-<roadmap-id>.md`

Use [ADR Modes](../../share-adr/references/modes.md) to select an ADR location. A roadmap retrospective is a temporary knowledge-transfer report; extract durable decisions into ADRs before removing it.
