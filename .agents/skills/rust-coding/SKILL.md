---
name: rust-coding
description: >-
  Index of concrete Rust production-code practices. Use for Rust application
  architecture, Topcoat or Datastar web UI, SSE design, workflow engines, LLM
  integration, Serde and garde input boundaries, tracing, or Rust library
  selection. Apply share-coding first. Use rust-test for executable tests.
---

# Rust Coding Index

Apply [`share-coding`](../share-coding/SKILL.md) before choosing Rust-specific boundaries or libraries. Load only the reference that matches the implementation concern.

## Web UI

- [`web-ui-topcoat-datastar.md`](references/web-ui-topcoat-datastar.md) — Topcoat and Datastar responsibilities, reactive ownership, server-rendered partial HTML, URL state, and minimal reconnect-safe SSE design.

## Application libraries

- [`application-libraries.md`](references/application-libraries.md) — preferred Rust libraries for LLMs, workflows, input parsing and validation, logging, and dependency versioning.

## Related skills

- [`rust-test`](../rust-test/SKILL.md) — Rust unit, white-box, integration, black-box, and rustdoc test placement.
- [`share-test`](../share-test/SKILL.md) — language-independent test philosophy.
- [`share-test-design-flow`](../share-test-design-flow/SKILL.md) — concrete test design and human-facing QA reports.
