---
confirmed: true
---

# ADR: consolidate coding conventions into the totto2727-coding plugin

## Context

The 2026-05-04 workflow consolidated totto2727-specific coding, testing, and generated external specification references into one plugin. The temporary migration research is not durable, but the plugin boundary decision is.

## Decision

Keep coding conventions and external coding references in `plugins/totto2727-coding` rather than mixing them into workflow or roadmap plugins:

- Hand-written coding/test conventions live behind stable coding/test skill entrypoints.
- Generated documentation references, such as MoonBit and components-build references, stay separate from hand-written conventions.
- Marketplace/plugin manifests advertise `totto2727-coding` as an independent plugin.
- Workflow/roadmap plugins may link to coding skills but do not own language-specific implementation rules.

## Consequences

The dev-flow plugin can be reduced to roadmap governance and reusable document formats. Coding rules evolve independently and can be reused by oh-my-codingagent or other agents without importing workflow-level procedures.
