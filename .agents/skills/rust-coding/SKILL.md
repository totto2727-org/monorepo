---
name: rust-coding
description: >-
  Rust implementation guidance for web UI, SSE, workflows, LLM integration, input boundaries, tracing, and library selection. Use when implementing or reviewing these concerns.
---

# Rust Coding Index

Use [`share-coding`](../share-coding/SKILL.md) for language-independent design decisions.
Load only the reference that matches the implementation concern; already available principles need not be reloaded.

## Web UI

- [`web-ui-topcoat-datastar.md`](references/web-ui-topcoat-datastar.md) — Topcoat and Datastar responsibilities, reactive ownership, server-rendered partial HTML, URL state, and minimal reconnect-safe SSE design.

## Application libraries

- [`application-libraries.md`](references/application-libraries.md) — preferred Rust libraries for LLMs, workflows, input parsing and validation, logging, and dependency versioning.

## Related skills

- [`rust-test`](../rust-test/SKILL.md) — Rust unit, white-box, integration, black-box, and rustdoc test placement.
- [`share-test`](../share-test/SKILL.md) — language-independent test philosophy.
- [`share-test-design`](../share-test-design/SKILL.md) — test-design decisions and suitable evidence presentation.
