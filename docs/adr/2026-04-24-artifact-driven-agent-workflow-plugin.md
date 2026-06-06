---
confirmed: true
---

# ADR: use an artifact-driven agent workflow plugin structure

## Context

`totto2727-dev-flow` provides reusable agent-workflow conventions as repository artifacts, not as hidden agent memory or runtime code. A lead agent coordinates bounded specialist work through explicit documents, while the plugin ships skills, agent entrypoints, templates, and authoring guides.

Claude Code did not support nested subagent orchestration, so an extra orchestrator tier would have made the design incompatible with the runtime. The plugin also needed resumable handoff files rather than hidden agent memory.

## Decision

Adopt an artifact-driven plugin structure with these durable rules:

- Keep a single lead/main coordination layer; specialists are invoked directly by the lead and do not launch nested specialists.
- Store durable handoff state in repository artifacts, especially progress YAML, intent/design/task/validation documents, ADRs, and retrospectives.
- Keep artifact formats in a shared skill with one authoring guide per template.
- Keep plugin content Markdown/YAML-first; no runtime code is required for the workflow plugin itself.
- Treat project rules and git safety rules as constraints inherited by every step rather than redefined per specialist.

## Consequences

Workflow state remains resumable and reviewable because it is stored in explicit artifacts. `totto2727-dev-flow` owns reusable artifact formats and authoring conventions; tactical execution orchestration belongs outside this repository-level plugin.
