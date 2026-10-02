# HTML rendering and dependencies

Read the relevant sections when adding code, formulas, diagrams, or interaction, or when delivery has offline or external-resource constraints.
Basic prose-only explanations do not need the optional rendering features below.

## Online and offline dependencies

A single HTML file is not necessarily self-contained or network-independent.
The unmodified template includes these external dependencies:

| Feature           | Network dependency                                                           | Loading and fallback behavior                                        |
| ----------------- | ---------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Code highlighting | Shiki from `esm.sh`, with its required assets                                | Loaded when code blocks exist; failures leave escaped plain code     |
| Mermaid diagrams  | Mermaid from `cdn.jsdelivr.net`                                              | Loaded when `.mermaid` elements exist; failures show diagram source  |
| Math rendering    | RaTeX module, font stylesheet, and associated assets from `cdn.jsdelivr.net` | Module and stylesheet are loaded from the head even without formulas |

Use these enhancements only when network access and external dependencies are acceptable for the document's audience and delivery environment.
CDN failures, browser security policy, and offline use can prevent rendering.
Raw diagram source is a diagnostic fallback, not an equivalent readable diagram.
Provide a nearby explanation when understanding must not depend on the renderer.

For strict offline or no-network delivery, adapt the generated copy of the template:

- Remove the external RaTeX stylesheet and module script from the head.
- Remove the calls to `enhanceCodeBlocks()`, `initFormulas()`, and `initMermaid()` from the final initialization block so no remaining content triggers CDN loaders.
- Use escaped plain code, HTML tables, inline SVG, CSS, or local Canvas behavior instead of network-rendered features.
- Replace Mermaid source with a readable local representation and formulas with suitable text or inline SVG.
- Check authored content, CSS, scripts, images, and fonts for additional external resource requests.

The inline navigation, steppers, toggles, and Canvas helpers do not require a CDN.
If external libraries are instead bundled locally, account for their module, font, and WASM assets and test the intended launch mode.
A multi-file bundle is not a single-file deliverable, and assets that work behind a local server may not work through `file://`.
Do not describe a document as offline-ready merely because a failed CDN request has a fallback.

## Optional diagrams and interaction

Choose a diagram when relationships, branches, or state transitions are easier to understand visually than in prose or code.
Choose a stepper only when inspecting intermediate states helps the reader understand a sequence.
Neither algorithms nor complex logic automatically require both a diagram and a stepper or code sample.
Avoid parallel representations that repeat the same information without adding understanding.

When a visualization is useful:

- Mermaid suits flowcharts, sequences, states, and dependencies when network rendering is acceptable.
- Inline SVG suits static diagrams and no-network delivery.
- CSS and HTML suit small state displays and tables.
- Canvas suits geometric or dynamic demonstrations where motion carries information.
- A range slider can expose a meaningful numeric parameter; a toggle can compare variants.
- A native `details` block can disclose secondary examples or edge cases without a custom interaction.

Use `<div class="mermaid">...</div>`, not a Markdown fence, for Mermaid in HTML.
Quote labels with `A["label"]` and `B{"question"}` and avoid unescaped punctuation in unquoted labels.
The template adds wheel zoom, drag-to-pan, and reset controls after rendering; do not duplicate that behavior.
PlantUML is not built in and can require a server or additional runtime, so establish acceptable dependencies before adding it.

For small steppers, `data-steps` holds a JSON array of objects with `title`, `body`, and optional `html` fields.
Escape the JSON for its enclosing HTML attribute, and use custom inline scripts only when the template's behavior is insufficient.
Keep essential explanations available without operating an interaction, and provide a text equivalent for information carried only by a visual.

## Code and math

Use escaped `<pre><code class="language-...">...</code></pre>` for code samples.
An optional `data-title` on `pre` supplies a filename or label.
Let the template own highlighting rather than injecting presentation markup into the code.
The `language-moonbit` mapping uses Shiki's Rust grammar as an approximation, not an authoritative MoonBit parser.

Prefer the project's language when concrete syntax helps the reader apply the explanation.
Clearly label pseudocode or simplified samples when exact executable syntax would distract, and do not omit error handling or checks that are central to the behavior being explained.

For online math rendering, use a `.math` element with `data-latex` and optional `data-fs`, such as:

```html
<span class="math" data-latex="x^2" data-fs="24">x²</span>
```

Include readable fallback text inside the element.
The current template waits for RaTeX registration and does not populate an empty element with LaTeX on load failure, so an empty span is not a reliable fallback.
Use `class="math display"` for display layout where useful.
For simple formulas, ordinary text or semantic HTML may be sufficient without a math renderer.
