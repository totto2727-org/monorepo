import { md } from 'mdts'
import type { MarkdownMetadata } from 'mdts'

export const meta = {
  frontmatter: {
    'allowed-tools': 'Read',
    compatibility: 'Requires an agent that supports the Agent Skills specification.',
    description: 'Demonstrates how mdts generates consumer-required YAML frontmatter from TypeScript metadata.',
    license: 'MIT',
    metadata: {
      author: 'mdts-example',
      version: '1.0',
    },
    name: 'mdts-skill-example',
  },
  title: 'mdts Skill Example',
} satisfies MarkdownMetadata

export default md`
Use this document as an example of generating a \`SKILL.md\` file from a typed TypeScript module.

## Instructions

1. Read the generated Markdown document.
2. Preserve its YAML frontmatter when distributing the skill.
3. Use the generated heading as the human-readable title.
`
