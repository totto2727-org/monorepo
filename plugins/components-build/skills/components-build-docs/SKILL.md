---
name: components-build-docs
description: >-
  Open standard specification for building modern UI components (by Vercel).
  Covers composition, accessibility, polymorphism, state management, styling
  with Tailwind, design tokens, type-safe props, data attributes, and
  distribution via npm/registry/marketplace. Use when designing reusable
  component APIs, building design systems, or following component best practices.
  Common triggers: "component composition", "compound components", "asChild",
  "data-slot", "component registry", "design tokens", "components.build".
  Do NOT use for: general React questions unrelated to component design spec,
  specific library APIs (Radix, shadcn/ui installation).
metadata:
  author: totto2727
  version: 0.1.0
---

<!-- Generated from https://www.components.build/sitemap.xml -->
<!-- Run .script/generate-skill.ts to update -->

## Overview

components.build is an open-source specification established by Vercel for designing and building modern UI components. It defines a formal standard for creating composable, accessible, and adoptable components for the web.

The specification is framework-agnostic in its principles but uses React for examples. It covers the full lifecycle of component development — from API design and composition patterns to styling, state management, accessibility, and distribution.

### Key Principles

- **Composability over inheritance** — Break monolithic components into small, focused subcomponents with clear APIs
- **Accessible by default** — Semantic HTML, keyboard navigation, ARIA patterns, and focus management
- **Transparency** — Developers should understand and be able to modify component internals
- **Theming via design tokens** — Semantic CSS variable layers that separate intent from appearance

### Topics Covered

- **Design**: Composition, polymorphism (`as`/`asChild`), type-safe props, data attributes
- **Behavior**: Controlled/uncontrolled state, accessibility patterns
- **Styling**: Tailwind + `cn` utility, Class Variance Authority, design tokens
- **Distribution**: NPM packages, component registries (source-code distribution), marketplaces

## Related Skills

- [vercel-composition-patterns](https://raw.githubusercontent.com/vercel-labs/agent-skills/refs/heads/main/skills/composition-patterns/SKILL.md) — React composition patterns (compound components, boolean prop avoidance, state lifting, React 19 APIs). Complements this spec's Composition and State topics with concrete Incorrect/Correct rule pairs for code generation and refactoring.

## How to Use

1. Fetch the relevant documentation with `curl` or WebFetch before answering questions about that topic.
2. If a specific slug returns 404 or is unavailable, fall back to the overview at `https://www.components.build/`.
3. For composition and state patterns, also fetch the Vercel AGENTS.md for concrete rule pairs.

```
curl https://www.components.build/llms.mdx/{slug}
```

```
curl https://raw.githubusercontent.com/vercel-labs/agent-skills/refs/heads/main/skills/composition-patterns/AGENTS.md
```

## Documentation Links

| Slug              | Title           | Description                                                                                                                                                  |
| ----------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `accessibility`   | Accessibility   | Building components that are usable by everyone, including users with disabilities who rely on assistive technologies.                                       |
| `as-child`        | asChild         | How to use the `asChild` prop to render a custom element within the component.                                                                               |
| `composition`     | Composition     | The foundation of building modern UI components.                                                                                                             |
| `data-attributes` | Data Attributes | Using data attributes for declarative styling and component identification.                                                                                  |
| `definitions`     | Definitions     | This page establishes precise terminology used throughout the specification. Terms are intentionally framework agnostic, but we will use React for examples. |
| `design-tokens`   | Design Tokens   | How semantic naming conventions and design tokens create a flexible, maintainable theming system.                                                            |
| `docs`            | Docs            | How to document your components.                                                                                                                             |
| `marketplaces`    | Marketplaces    | Using component marketplaces to share your components.                                                                                                       |
| `npm`             | NPM             | How to publish your components to NPM.                                                                                                                       |
| `polymorphism`    | Polymorphism    | How to use the `as` prop to change the rendered HTML element while preserving component functionality.                                                       |
| `principles`      | Core Principles | When building modern UI components, it's important to keep these core principles in mind.                                                                    |
| `registry`        | Registry        | Understand the concept of component registries, how they work, and why they're revolutionizing how developers share and discover UI components.              |
| `state`           | State           | How to manage state in a component, as well as merging controllable and uncontrolled state.                                                                  |
| `styling`         | Styling         | Conditional and composable styling with Tailwind classes.                                                                                                    |
| `types`           | Types           | Extending the browser's native HTML elements for maximum customization.                                                                                      |

## Triggering Examples

Should trigger:

- "components.build の composition パターンについて教えて"
- "コンポーネントの asChild の使い方"
- "design tokens の設計方法"
- "compound components の命名規約"
- "component registry の作り方"

Should NOT trigger:

- "React の useState の使い方" (general React question)
- "shadcn/ui のインストール方法" (specific library setup)
- "Radix UI の Dialog API" (specific library API)
