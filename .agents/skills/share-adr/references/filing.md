# ADR Filing

> Document type: concrete ADR operating policy.

Use the [ADR authoring guide](../../share-artifacts/references/adr.md) for content requirements and the [ADR template](../../share-artifacts/templates/adr.md) for the file skeleton.

## Filing process

1. Select General or Roadmap mode using [ADR Modes](modes.md).
2. Choose the matching storage directory:
   - General: `docs/adr/`
   - Roadmap: `docs/roadmap/<roadmap-id>/adr/`
3. Name the file `<YYYY-MM-DD>-<title>.md`.
4. Write the proposal with `confirmed: false`.
5. Ask the decision owner to review the ADR itself.
6. After approval, set `confirmed: true`.

Create an `adr/` directory only when filing its first record. Do not commit empty directories.

## Directory layout

```text
docs/
|-- adr/
|   `-- <YYYY-MM-DD>-<title>.md
`-- roadmap/
    `-- <roadmap-id>/
        |-- roadmap.md
        |-- milestones/
        |-- progress.yaml
        `-- adr/
            `-- <YYYY-MM-DD>-<title>.md
```

Do not place ADRs inside implementation-specific artifact directories. Decisions confined to one implementation effort belong in that effort's design artifact.
