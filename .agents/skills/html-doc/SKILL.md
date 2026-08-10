---
name: html-doc
description: Create standalone explanatory HTML documents with inline CSS and JavaScript, interactive diagrams, Mermaid support, code blocks, and lightweight canvas/CSS visualizations. Use when turning technical notes, algorithms, or API explanations into self-contained browser-readable documentation.
---

# HTML Doc Skill

Use this skill when the user asks for an explanatory HTML document, especially when the document should include dynamic movement, diagrams, charts, algorithm walkthroughs, or annotated code blocks.

## Output Goal

Generate a single `.html` file that can be opened directly in a browser. Prefer one document per topic or module. The document is primarily for an agent or technically skilled maintainer, not a polished public website.

## Default Format

Start from `templates/standalone.html` and replace the placeholders:

- `{{TITLE}}`
- `{{SUMMARY}}`
- `{{CONTENT}}`
- `{{BOOTSTRAP_DATA}}`

Keep CSS and local behavior inline. Mermaid is allowed through the built-in dynamic CDN loader in the template. If offline/no-network operation is required, avoid Mermaid and use SVG, Canvas, CSS boxes, or HTML tables instead.

## Diagram Rules

- Prefer Mermaid for flowcharts, sequence diagrams, state diagrams, class-ish overviews, and dependency graphs.
- For complex logic, show both a compact implementation-shaped code sample in the project's language and a Mermaid flowchart. For simple logic, use either the code sample or the Mermaid flowchart, whichever is clearer.
- Quote Mermaid node labels with `A["label"]` and decision labels with `B{"question"}`. Avoid raw semicolons, `<`, `>`, slash-heavy labels, and unescaped punctuation inside unquoted nodes because Mermaid parsing is fragile.
- Mermaid diagrams rendered by the template are interactive: wheel to zoom, drag to pan, and use the reset button to restore the initial view. Do not add custom pan/zoom code in generated content.
- Do not use PlantUML by default. Browser-side PlantUML usually needs a server endpoint, encoded URLs, or a large WASM/runtime dependency. If the user explicitly requests PlantUML, ask whether a server/CDN dependency is acceptable.
- If Mermaid becomes awkward, use inline SVG for static diagrams, Canvas for dynamic algorithm motion, and CSS/HTML for small state-machine or matrix visualizations.
- For algorithm explanations, include both a high-level flow diagram and one interactive stepper.

## Code Block Rules

- Use `<pre><code class="language-...">` blocks.
- Add `data-title="..."` when the code block needs a filename or label.
- Keep code blocks plain text in generated content. Do not inject presentation markup or behavior outside the template.
- Code block formatting is owned by `templates/standalone.html`. When generating a document, preserve `<pre><code class="language-...">...</code></pre>` exactly and let the template handle rendering.
- The default template loads Shiki dynamically from CDN and replaces each source `<pre><code>` with Shiki's generated dark-theme HTML. If Shiki cannot load or a grammar fails, it falls back to a plain escaped `<pre><code>`.
- `language-moonbit` is mapped to Shiki's `rust` grammar as an approximate fallback unless a better grammar is added later.
- Do not put language-neutral pseudocode in code blocks. Convert it to a simplified code sample in the project's language. Omit incidental details such as null checks when they distract from the core algorithm.

## Math Rules

- Do not put formulas in `language-text` code blocks.
- Render formulas with RaTeX via `<span class="math" data-latex="..." data-fs="24"></span>` for inline or display math.
- The template loads `ratex-wasm` from CDN and dynamically creates `<ratex-formula>` after fonts are ready. If RaTeX fails, the original LaTeX text remains visible.

## Interaction Patterns

Use the smallest interaction that improves understanding:

- Stepper: for algorithms with a clear sequence.
- Range slider: for parameterized geometry or numeric examples.
- Toggle buttons: for comparing variants such as strict vs inclusive predicates.
- Canvas: for geometric motion, clipping, interpolation, or distance visualization.
- Details blocks: for expandable edge cases.

## Recommended Content Structure

```html
<section class="hero-card">
  <p class="eyebrow">module / algorithm name</p>
  <h1>Short title</h1>
  <p>One-paragraph summary.</p>
</section>

<section class="panel">
  <h2>Core Idea</h2>
  <p>Explain the invariant or mental model first.</p>
</section>

<section class="panel grid two">
  <div>
    <h2>Flow</h2>
    <div class="mermaid">...</div>
  </div>
  <div>
    <h2>State</h2>
    <div class="viz" data-viz="...">...</div>
  </div>
</section>

<section class="panel">
  <h2>Implementation Notes</h2>
  <pre data-title="example.mbt"><code class="language-moonbit">...</code></pre>
</section>
```

## Authoring Guidance

- Preserve identifiers exactly: function names, type names, enum variants, file names, and equations.
- Prefer concise Japanese explanations if the repository/user context is Japanese. Keep code, HTML attributes, CSS class names, and identifiers in English.
- Use `data-steps` JSON for steppers when the sequence is small. Use custom inline scripts only when the default template behavior is insufficient.
- Avoid external assets except Mermaid. Images should be replaced with SVG/Canvas where possible.

## Verification

After creating an HTML document:

1. Read the generated file enough to confirm placeholders were replaced.
2. Check that `<style>` and `<script>` are present inline.
3. Check that Mermaid diagrams use `<div class="mermaid">` and not Markdown fences.
4. If practical, open the file path or run a lightweight static check; no build step is required.
