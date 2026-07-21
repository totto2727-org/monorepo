---
confirmed: true
---

# ADR: consolidate coding conventions into the totto2727-coding plugin

## Context

Coding conventions, testing conventions, and generated external specification references belong to a dedicated coding plugin. Workflow and roadmap plugins should not own language-specific implementation rules.

## Decision

Keep coding conventions and external coding references in `plugins/totto2727-coding` rather than mixing them into workflow or roadmap plugins:

- Hand-written coding/test conventions live behind stable coding/test skill entrypoints.
- Generated documentation references, such as MoonBit and components-build references, stay separate from hand-written conventions.
- Marketplace/plugin manifests advertise `totto2727-coding` as an independent plugin.
- Workflow/roadmap plugins may link to coding skills but do not own language-specific implementation rules.

## Consequences

The dev-flow plugin stays focused on roadmap governance and reusable document formats. Coding rules evolve independently and can be reused by oh-my-codingagent or other agents without importing workflow-level procedures.

> Superseded by [Consolidate durable development guidance in totto2727-coding](2026-07-20-consolidate-development-guidance-in-coding-plugin.md)
