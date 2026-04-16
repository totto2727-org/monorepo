// Fetches components.build sitemap, extracts English slugs, and generates a
// SKILL.md with links to /llms.mdx/{slug} endpoints.
//
// Usage:
//   deno run --allow-net --allow-read --allow-write .script/generate-skill.ts

import { join } from 'jsr:@std/path@1.1.4'

const SITEMAP_URL = 'https://www.components.build/sitemap.xml'
const BASE_URL = 'https://www.components.build'

const scriptDir = import.meta.dirname
const projectRoot = join(scriptDir, '..')
const outputDir = join(projectRoot, 'skills', 'components-build-docs')

// Fetch sitemap
const sitemapResponse = await fetch(SITEMAP_URL)
if (!sitemapResponse.ok) {
  console.error(`Failed to fetch sitemap: ${sitemapResponse.status} ${sitemapResponse.statusText}`)
  Deno.exit(1)
}
const sitemapXml = await sitemapResponse.text()

// Extract URLs from sitemap
const locRegex = /<loc>([^<]+)<\/loc>/g
const urls: string[] = []
let match: RegExpExecArray | null
while ((match = locRegex.exec(sitemapXml)) !== null) {
  urls.push(match[1])
}

// Extract unique slugs (skip home page and nested paths)
const slugs = new Set<string>()

for (const url of urls) {
  const path = new URL(url).pathname
  if (path === '/' || path === '') {
    continue
  }
  const slug = path.replace(/^\//, '').replace(/\/$/, '')
  // Only top-level slugs (no slashes)
  if (slug && !slug.includes('/')) {
    slugs.add(slug)
  }
}

const sortedSlugs = [...slugs].toSorted()
console.log(`Found ${sortedSlugs.length} unique slugs`)

// Fetch title and description from /llms.mdx/{slug} frontmatter
interface DocEntry {
  slug: string
  title: string
  description: string
}

function parseFrontmatter(text: string): Record<string, string> {
  const fmMatch = text.match(/^---\s*\n([\s\S]*?)\n---/)
  if (!fmMatch) {
    return {}
  }

  const result: Record<string, string> = {}
  for (const line of fmMatch[1].split('\n')) {
    const colonIdx = line.indexOf(':')
    if (colonIdx === -1) {
      continue
    }
    const key = line.slice(0, colonIdx).trim()
    const value = line
      .slice(colonIdx + 1)
      .trim()
      .replaceAll(/^["']|["']$/g, '')
    if (key && value) {
      result[key] = value
    }
  }
  return result
}

const entries: DocEntry[] = []

for (const slug of sortedSlugs) {
  const llmsUrl = `${BASE_URL}/llms.mdx/${slug}`
  try {
    const response = await fetch(llmsUrl)
    if (!response.ok) {
      console.warn(`Skipping ${slug}: ${response.status}`)
      continue
    }
    const text = await response.text()
    const fm = parseFrontmatter(text)
    entries.push({
      description: fm.description || '',
      slug,
      title: fm.title || slug,
    })
    console.log(`  ${slug}: ${fm.title || '(no title)'}`)
  } catch (error) {
    console.warn(`Skipping ${slug}: ${error}`)
  }
}

// Generate SKILL.md
await Deno.mkdir(outputDir, { recursive: true })

const rows = entries
  .map((e) => {
    const desc = e.description || ''
    return `| \`${e.slug}\` | ${e.title} | ${desc} |`
  })
  .join('\n')

const skillContent = `---
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

- **Design**: Composition, polymorphism (\`as\`/\`asChild\`), type-safe props, data attributes
- **Behavior**: Controlled/uncontrolled state, accessibility patterns
- **Styling**: Tailwind + \`cn\` utility, Class Variance Authority, design tokens
- **Distribution**: NPM packages, component registries (source-code distribution), marketplaces

## Related Skills

- [vercel-composition-patterns](https://raw.githubusercontent.com/vercel-labs/agent-skills/refs/heads/main/skills/composition-patterns/SKILL.md) — React composition patterns (compound components, boolean prop avoidance, state lifting, React 19 APIs). Complements this spec's Composition and State topics with concrete Incorrect/Correct rule pairs for code generation and refactoring.

## How to Use

1. Fetch the relevant documentation with \`curl\` or WebFetch before answering questions about that topic.
2. If a specific slug returns 404 or is unavailable, fall back to the overview at \`https://www.components.build/\`.
3. For composition and state patterns, also fetch the Vercel AGENTS.md for concrete rule pairs.

\`\`\`
curl https://www.components.build/llms.mdx/{slug}
\`\`\`

\`\`\`
curl https://raw.githubusercontent.com/vercel-labs/agent-skills/refs/heads/main/skills/composition-patterns/AGENTS.md
\`\`\`

## Documentation Links

| Slug | Title | Description |
|------|-------|-------------|
${rows}

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
`

await Deno.writeTextFile(join(outputDir, 'SKILL.md'), skillContent)

console.log(`\nGenerated SKILL.md with ${entries.length} links in ${outputDir}`)
