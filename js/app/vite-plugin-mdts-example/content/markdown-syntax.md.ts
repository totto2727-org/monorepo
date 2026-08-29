import { md } from 'vite-plugin-mdts'

export const meta = { title: 'Markdown Syntax' }

export default md`
# Markdown Syntax

This document demonstrates common CommonMark and GitHub Flavored Markdown syntax.

## Headings

### Heading level 3

#### Heading level 4

##### Heading level 5

###### Heading level 6

## Paragraphs and line breaks

Separate paragraphs with an empty line. This sentence belongs to the first paragraph.

This is the second paragraph.\\
A trailing backslash creates a hard line break.

## Emphasis

Use _italic text_, **bold text**, _**bold italic text**_, and ~~strikethrough text~~.

## Blockquotes

> Markdown can contain blockquotes.

> A blockquote can continue across multiple paragraphs.

## Alerts

Comark's default [alert plugin](https://comark.dev/plugins/defaults/alert) supports GitHub-style alerts:

> [!NOTE]
  Useful information that users should know, even when skimming content.

> [!TIP]
  Helpful advice for doing things better or more easily.

> [!IMPORTANT]
  Key information users need to know to achieve their goal.

> [!WARNING]
  Urgent information that needs immediate attention to avoid problems.

> [!CAUTION]
  Risks or negative outcomes of an action.

## Lists

Unordered lists can be nested:

- First item
- Second item
  - Nested item
  - Another nested item

Ordered lists use numbers:

1. First step
2. Second step
3. Third step

Comark's default [task list plugin](https://comark.dev/plugins/defaults/task-list) supports checked, unchecked, and nested tasks:

- [x] Completed task
- [ ] Pending task
- [x] Parent task
  - [x] Nested task completed
  - [ ] Nested task pending

## Links and images

Use an [inline link](https://example.com), or write an autolink such as <https://example.com>.

![Comark banner](https://raw.githubusercontent.com/comarkdown/comark/main/assets/banner.jpg)

## Code

Inline code looks like \`const message = 'Hello, mdts'\`.

~~~typescript
const greeting = (name: string): string => \`Hello, \${name}!\`

console.log(greeting('mdts'))
~~~

## Tables

| Syntax        |   Result    | GFM |
| :------------ | :---------: | --: |
| \`*italic*\`    |  _italic_   | Yes |
| \`**bold**\`    |  **bold**   | Yes |
| \`~~removed~~\` | ~~removed~~ | Yes |

## Horizontal rule

Content before the rule.

---

Content after the rule.

## Escaping characters

Backslashes keep punctuation literal: \\_not italic\\_ and \\# not a heading.
`
