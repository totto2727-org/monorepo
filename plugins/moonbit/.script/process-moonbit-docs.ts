// Fetches MoonBit official documentation markdown and generates skill reference files.
//
// Source pages:
//   - Language: https://docs.moonbitlang.com/en/latest/language/index.html
//   - Toolchain: https://docs.moonbitlang.com/en/latest/toolchain/index.html
//
// Download links (pass these as arguments):
//   sfw deno run --allow-net --allow-read --allow-write .script/process-moonbit-docs.ts \
//     https://docs.moonbitlang.com/en/latest/_downloads/78d8998d78e60fd7b1b2f4c9bb2819fb/summary.md \
//     https://docs.moonbitlang.com/en/latest/_downloads/7e67a7065021137fc80a2750bac9ee32/summary.md

import { join } from 'jsr:@std/path@1.1.4'

const urls = Deno.args
if (urls.length === 0) {
  console.error('Usage: deno run --allow-net --allow-read --allow-write .script/process-moonbit-docs.ts <URL> [URL...]')
  Deno.exit(1)
}

const scriptDir = import.meta.dirname
const projectRoot = join(scriptDir, '..')
const outputDir = join(projectRoot, 'skills', 'moonbit-docs')

try {
  await Deno.remove(outputDir, { recursive: true })
} catch (error) {
  if (!(error instanceof Deno.errors.NotFound)) {
    throw error
  }
}
await Deno.mkdir(outputDir, { recursive: true })

function parseSections(text: string): { path: string; content: string }[] {
  const sectionRegex = /<!-- path: (.+?) -->/g
  let match: RegExpExecArray | null
  const matches: { path: string; index: number }[] = []

  while ((match = sectionRegex.exec(text)) !== null) {
    matches.push({ index: match.index + match[0].length, path: match[1] })
  }

  const sections: { path: string; content: string }[] = []
  for (let i = 0; i < matches.length; i++) {
    const start = matches[i].index
    const end = i + 1 < matches.length ? text.lastIndexOf('<!-- path:', matches[i + 1].index) : text.length
    sections.push({
      content: text.slice(start, end).trim(),
      path: matches[i].path,
    })
  }
  return sections
}

const sections: { path: string; content: string }[] = []
for (const url of urls) {
  const response = await fetch(url)
  if (!response.ok) {
    console.error(`Failed to fetch ${url}: ${response.status} ${response.statusText}`)
    Deno.exit(1)
  }
  const text = await response.text()
  sections.push(...parseSections(text))
}

const licenseHeader = [
  '<!-- Derived from MoonBit documentation by moonbitlang -->',
  '<!-- https://github.com/moonbitlang/moonbit-docs -->',
  '<!-- Prose content (post July 4, 2024): CC BY-SA 4.0 -->',
  '<!-- Code examples: Apache 2.0 -->',
  '<!-- Modifications: Extracted and reformatted as Claude Code skill files -->',
].join('\n')

function toKebab(heading: string): string {
  return heading
    .toLowerCase()
    .replaceAll(/[^a-z0-9\s-]/g, '')
    .trim()
    .replaceAll(/\s+/g, '-')
}

function splitByHeading(content: string, baseFilename: string, level: string): { filename: string; content: string }[] {
  const headingRegex = new RegExp(`^${level} (.+)$`, 'gm')
  const headings: { title: string; index: number }[] = []
  let m: RegExpExecArray | null
  while ((m = headingRegex.exec(content)) !== null) {
    headings.push({ index: m.index, title: m[1] })
  }
  if (headings.length <= 1) {
    return [{ content, filename: baseFilename }]
  }
  const result: { filename: string; content: string }[] = []
  for (let i = 0; i < headings.length; i++) {
    const start = headings[i].index
    const end = i + 1 < headings.length ? headings[i + 1].index : content.length
    const slug = toKebab(headings[i].title)
    const fname = baseFilename.replace(/\.md$/, `-${slug}.md`)
    result.push({ content: content.slice(start, end).trim(), filename: fname })
  }
  return result
}

const otherFiles: { filename: string; title: string }[] = []

for (const section of sections) {
  if (section.path === 'language/index.md') {
    continue
  }

  if (section.path === 'language/introduction.md') {
    continue
  }

  const baseFilename = section.path.replace(/\.md$/, '').replaceAll('/', '-').replaceAll('_', '-') + '.md'

  const isFundamentals = section.path === 'language/fundamentals.md'
  const subFiles = isFundamentals
    ? splitByHeading(section.content, baseFilename, '###')
    : [{ content: section.content, filename: baseFilename }]

  for (const sub of subFiles) {
    otherFiles.push({ filename: sub.filename, title: sub.filename })
    await Deno.writeTextFile(join(outputDir, sub.filename), licenseHeader + '\n\n' + sub.content + '\n')
  }
}

const introSection = sections.find((s) => s.path === 'language/introduction.md')
const links = otherFiles.map((f) => `- [${f.title}](./${f.filename})`).join('\n')

const relatedSkillsBlock = `## Related Skills

- [moonbit-bestpractice](../moonbit-bestpractice/SKILL.md) — MoonBit coding standards and best practices. Use when writing, reviewing, or refactoring MoonBit code.`

const skillContent = `---
name: moonbit-docs
description: >-
  MoonBit language reference covering syntax, types, functions, methods, and
  deriving. Use when writing MoonBit code, debugging MoonBit programs, or
  answering questions about MoonBit syntax and features.
---

${licenseHeader}

${relatedSkillsBlock}

${introSection?.content ?? ''}

## Related Documentation

${links}
`

await Deno.writeTextFile(join(outputDir, 'SKILL.md'), skillContent)

console.log(`Generated ${otherFiles.length + 1} files in ${outputDir}`)
