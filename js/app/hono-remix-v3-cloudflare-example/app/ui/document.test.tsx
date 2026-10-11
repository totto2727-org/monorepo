import { renderToString } from 'remix/component/server'
import { describe, expect, it } from 'vite-plus/test'

import { Document } from './document.tsx'

describe('Document', () => {
  it('renders the supplied document props and Vite entry script', async () => {
    const html = await renderToString(
      <Document lang='ja' title='Document props'>
        <main>Rendered children</main>
      </Document>,
    )

    expect(html).toContain('<html lang="ja">')
    expect(html).toContain('<title>Document props</title>')
    expect(html).toContain('<main>Rendered children</main>')
    expect(html).toContain('<script type="module" src="/app/assets/entry.ts">')
  })

  it('keeps the default language and title when optional props are absent', async () => {
    const html = await renderToString(<Document />)

    expect(html).toContain('<html lang="en">')
    expect(html).toContain('<title>Hono Remix Example</title>')
  })
})
