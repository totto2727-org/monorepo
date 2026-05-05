import type { Handle, Props } from 'remix/ui'

import type { FrameName } from '../routes.ts'

export type FrameLinkProps = Props<'a'> & {
  href: string
  'rmx-target': FrameName
  'rmx-src': string
}

/**
 * Anchor that always navigates a named frame. The three required props match
 * the actual HTML attributes the runtime reads off the link element:
 *
 * - `href`        — URL pushed to the address bar / history.
 * - `rmx-target`  — name of the `<Frame>` to reload. Constrained to a value
 *                   declared in `frames` (routes.ts), so a typo or stray name
 *                   fails at the type level.
 * - `rmx-src`     — URL the named frame fetches; intentionally required even
 *                   when equal to `href` so the dual-URL aspect is always
 *                   visible at the call site.
 *
 * Any other anchor prop (`class`, `aria-label`, `title`, …) is allowed via
 * `Props<'a'>` and forwarded as-is.
 */
export const FrameLink = (handle: Handle<FrameLinkProps>) => () => {
  const { children, ...rest } = handle.props
  return <a {...rest}>{children}</a>
}
