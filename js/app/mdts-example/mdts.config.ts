import footnotes from '@comark/html/plugins/footnotes'
import math, { Math } from '@comark/html/plugins/math'
import mermaid, { Mermaid } from '@comark/html/plugins/mermaid'
import shiki from '@comark/html/plugins/shiki'
import { defineConfig } from 'mdts'

export default defineConfig({
  input: './content',
  output: './dist',
  preview: {
    comark: {
      components: { Math, Mermaid },
      plugins: [footnotes(), math(), mermaid({ theme: 'tokyo-night', themeDark: 'tokyo-night' }), shiki()],
    },
  },
})
