# totto2727-dev-flow

Roadmap-level development flow plugin for agentic development systems.

This plugin keeps only the strategic roadmap layer and shared document formats. Workflow-level execution (intent clarification, research, implementation, review, validation, and PR/CI handling) is delegated to the agents or execution systems that own each milestone.

## Skills

- `roadmap` — top-level roadmap planning and milestone tracking.
- `roadmap-intent` — capture the worldview, scope, non-scope, and success boundary of a roadmap.
- `roadmap-decomposition` — split a roadmap into observable milestones.
- `roadmap-retrospective` — close out roadmap-level learning.
- `share-artifacts` — authoring guides and templates for roadmap, milestone, ADR, and retained QA test design formats.
- `share-adr` — ADR writing rules.

## State management

Roadmap progress is stored at `docs/roadmap/<roadmap-id>/progress.yaml` and must be read or changed through the repository roadmap CLI (`@totto2727/roadmap`). Direct editing of `progress.yaml` is reserved for CLI implementation work only.

## Directory convention

A roadmap directory keeps the active planning surface small:

- `roadmap.md`
- `progress.yaml`
- `milestones/`
- `adr/`
- `tmp/` for temporary or non-canonical notes when they must be retained
