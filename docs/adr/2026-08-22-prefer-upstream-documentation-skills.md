---
confirmed: true
scope: general
---

# ADR: prefer upstream documentation skills

- **Filed at:** 2026-08-22
- **Decision owner:** repository owner
- **Origin:** official documentation skill distribution audit
- **Storage path:** `docs/adr/2026-08-22-prefer-upstream-documentation-skills.md`

## Context

The coding plugin previously generated and committed `docs-moonbit` and `docs-components-build` from upstream documentation. MoonBit and components.build now publish official Agent Skills, so the generated copies duplicate maintained upstream resources and can become stale. Consumers still need a deterministic local skill when it is installed and a direct official documentation path when it is not. This record supersedes the combined 2026-07-20 decision, so it must also preserve that decision's unrelated active guidance boundaries.

## Decision

Keep `totto2727-dev-flow` deleted. Retain only its reusable ADR and artifact guidance in `totto2727-coding`, and keep roadmap execution orchestration outside both plugins. Preserve the responsibility boundaries established by the superseded record:

- `share-coding` and `share-test` own language-independent principles in their `SKILL.md` files.
- `js-coding`, `mbt-coding`, `js-test`, and `mbt-test` index concrete language-specific practices.
- `share-test-design-flow` owns concrete test design and human-facing reports.
- `share-artifact` owns README, AGENTS, and ADR authoring policy, guides, and templates.

For documentation-backed guidance, prefer an upstream official Agent Skill whenever the documentation owner publishes one. Install that skill with `vpx skills`, record its canonical source in `skills-lock.json`, and remove the superseded custom skill and generator. Referencing skills must name the official skill, use its local installation when available, and provide a direct official-source fallback. Prefer a verified Markdown-native endpoint; if content negotiation advertises Markdown but returns HTML, link the maintained upstream Markdown source instead.

When no official skill exists, keep the custom skill self-contained: place its generator under the skill's `scripts/` directory, ignore generated `references/`, regenerate missing references on demand using the upstream URL hierarchy, and always generate `references/index.md` when it is absent.

<!-- prettier-ignore-start -->

| Option | Summary | Result | Rationale |
| --- | --- | --- | --- |
| Prefer official upstream skills | Install the documentation owner's skill and retain a direct site fallback. | Adopted | Keeps local guidance aligned with the maintained source while preserving access without the skill. |
| Continue committing generated copies | Retain custom docs skills and shared generators even after upstream skill publication. | Rejected | Duplicates upstream maintenance and preserves avoidable generated content in Git. |
| Use websites only | Remove local skills and always fetch documentation over the network. | Rejected | Loses local progressive disclosure and makes every use depend on network availability. |

<!-- prettier-ignore-end -->

## Consequences

- **Added:** Canonical upstream skill entries in `skills-lock.json`, local-first routing, direct Markdown fallbacks, and a per-skill generation contract for future sites without official skills.
- **Existing impact:** `docs-moonbit`, `docs-components-build`, their generated references, and their shared generators are removed; dependent guidance uses `moonbit-orientation` and `building-components`.
- **Future constraints:** A docs-backed skill must be audited for an official distribution before custom generation is added, and transient feature-branch sources must not remain in the final lock.
- **Costs and limitations:** Upstream skill changes remain a supply-chain dependency and require normal lock review; direct site fallbacks still require network access.

## Related records

- [Consolidate durable development guidance in totto2727-coding](2026-07-20-consolidate-development-guidance-in-coding-plugin.md)

_This ADR was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [ADR template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/adr/template.md)._
