# Focused unit

## Applicability and context

Use `focused-unit` for a section or paragraph group within a developer document's larger purpose.
Read the unit's heading, surrounding explanation, and document purpose before deciding what is extraneous.
Review English source documents, not translated editions.
Use these examples for follow-up review, not as samples or expected labels in blind model input.

## Illustrative comparison

This hypothetical ingestion service validates requests, queues accepted events, and stores them asynchronously.
The architecture section explains why acceptance does not mean that storage has finished.

**Problematic**

> The receiver validates an event and places it in the queue before acknowledging acceptance.
> To customize report exports, set the output format and destination in the export settings.
> A separate writer consumes queued events and stores them later.

**Improved**

> The receiver acknowledges an event after validation and queueing, without waiting for storage.
> A separate writer consumes the queue and stores events asynchronously.

```text
Incoming event -> Validate
                     | invalid -> Reject
                     | valid
                     v
                   Queue -> Acknowledge acceptance
                     |
                     v
                   Writer -> Store
```

### Why this diagnosis

The export instructions interrupt the explanation of the acceptance boundary.
The improved unit keeps the related stages together, and the diagram makes the two outcomes of queueing visible.
The larger document can still contain export configuration in its own section.
Coherence does not require an entire document to answer only one question.

## Exceptions and false positives

- A section may combine definitions, causes, consequences, and examples that jointly explain one subject.
- Preserve prerequisites, constraints, failure conditions, and explanations needed to interpret the unit.
- Keep diagrams, code, tables, and warnings with the prose that gives them meaning.
- Summaries and repetition can aid orientation or learning, but short units need no generic introduction or summary.
- Related independent tasks can share a page under distinct headings when that supports the larger purpose.

## Inspect and fix a failure

1. State the unit's reader question and its contribution to the document's purpose.
2. Distinguish a necessary supporting explanation from an unrelated or independent topic.
3. Remove empty repetition and move interruptions to suitable sections without discarding useful content.
4. Preserve direct references when readers need to find the relocated topic.
5. Reread the surrounding sections to ensure the edit did not fragment a coherent explanation.

## Abstention boundaries

- `not_applicable`: the selection is not a meaningful explanatory or instructional unit, such as a raw identifier list.
- `insufficient_context`: the purpose or neighboring material needed to judge coherence is missing.
- Brevity is neither failure nor inapplicability, and a one-sentence unit can be complete.
