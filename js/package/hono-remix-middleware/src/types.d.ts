// Opt-in module augmentation that gives c.render the default
// `(content) => Response` shape with no extra render props.
//
// Apps that need a different ContextRenderer signature should declare it
// themselves instead of importing this file.

import type { RemixNode } from 'remix/ui'

declare module 'hono' {
  interface ContextRenderer {
    (content: RemixNode): Response
  }
}

export {}
