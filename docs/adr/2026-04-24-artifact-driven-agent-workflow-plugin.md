---
confirmed: true
---

# ADR: use an artifact-driven agent workflow plugin structure

## Context

The 2026-04-24 workflow bootstrap established the original AI-DLC-derived plugin as a Markdown-only Claude Code plugin. The useful decision was not the temporary research trail, but the operating model: a lead agent coordinates bounded specialist work through durable artifacts, while the plugin itself ships skills, agent entrypoints, templates, and authoring guides.

Claude Code did not support nested subagent orchestration, so an extra orchestrator tier would have made the design incompatible with the runtime. The plugin also needed resumable handoff files rather than hidden agent memory.

## Decision

Adopt an artifact-driven plugin structure with these durable rules:

- Keep a single lead/main coordination layer; specialists are invoked directly by the lead and do not launch nested specialists.
- Store durable handoff state in repository artifacts, especially progress YAML, intent/design/task/validation documents, ADRs, and retrospectives.
- Keep artifact formats in a shared skill with one authoring guide per template.
- Keep plugin content Markdown/YAML-first; no runtime code is required for the workflow plugin itself.
- Treat project rules and git safety rules as constraints inherited by every step rather than redefined per specialist.

## Consequences

This made the workflow resumable and reviewable without depending on opaque agent state. It also created many tactical workflow artifacts; those tactical steps are now delegated to oh-my-codingagent, while the reusable artifact formats remain in `totto2727-dev-flow`.
