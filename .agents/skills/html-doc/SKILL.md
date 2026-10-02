---
name: html-doc
description: >-
  Create explanatory HTML documents from a reusable base template. Use when technical explanations, architecture notes, or algorithms should be delivered as browser-readable HTML.
---

# HTML Documents

Use [templates/standalone.html](templates/standalone.html) as a base for an explanatory document that opens directly in a browser.
Consult [documentation-principles](../../../totto2727-coding/skills/documentation-principles/SKILL.md) when deciding content, structure, or level of detail; reuse already-loaded guidance rather than rereading it for every document.
The template is not a requirement to build a complex visualization or a polished website.
A clear explanation with headings, prose, and a focused example may be the whole document.

## Template contract

Replace the following placeholders in the single `.html` file:

| Placeholder          | Content                                                           |
| -------------------- | ----------------------------------------------------------------- |
| `{{TITLE}}`          | Document title, used in the browser tab and existing hero heading |
| `{{SUMMARY}}`        | The conclusion or central idea the reader needs first             |
| `{{CONTENT}}`        | HTML sections that explain the topic                              |
| `{{BOOTSTRAP_DATA}}` | Valid JSON for local demos, or `{}` when unused                   |

The template already includes a hero section; do not duplicate it in `{{CONTENT}}`.
Set the document's `lang` attribute to match the prose.
Keep CSS and local behavior inline, and preserve identifiers, filenames, and equations accurately.
Escape text and attribute values for their HTML context, including code samples.
Serialize embedded JSON safely so a literal `</script>` cannot terminate its script element, for example by encoding `<` as `\u003c`.
Treat generated HTML, stepper content, and scripts as trusted authored content, not as a safe container for arbitrary untrusted input.

Add sections, navigation, grids, or disclosures only when they improve comprehension.
Direct child sections of `main` with IDs are included in the template's automatic navigation.

## Optional rendering and delivery constraints

Diagrams and steppers are optional, even for algorithms or complex logic.
Choose them only when they communicate something more clearly than prose or a focused example.
The default template makes external RaTeX requests even without formulas, so a single HTML file is not automatically offline-ready.

Read only the relevant sections of [rendering.md](references/rendering.md):

- [Online and offline dependencies](references/rendering.md#online-and-offline-dependencies) when deciding whether external resources are acceptable or preparing no-network delivery.
- [Optional diagrams and interaction](references/rendering.md#optional-diagrams-and-interaction) when adding visuals or interactive examples.
- [Code and math](references/rendering.md#code-and-math) when adding highlighted code or formulas.

## Verification appropriate to the document

Check that placeholders are replaced, bootstrap data is valid JSON, and content and links remain readable in the intended delivery mode.
Verify only the optional features actually used, including navigation targets, diagrams, formulas, controls, and narrow-screen layout when relevant.
For no-network delivery, test with network access disabled and check for attempted external requests, not just visible fallback text.
A static source check can establish structure but cannot establish browser rendering, interaction quality, or CDN availability.
Report which checks were performed and any remaining limitations without presenting unexecuted checks as successful.
