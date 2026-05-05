import type { Handle, RemixNode } from 'remix/ui'
import { createElement } from 'remix/ui'

import { isFrameRequest } from '../routes.ts'
import type { FrameName } from '../routes.ts'

/**
 * Builds a "page or frame" component from a Layout and a target frame name.
 *
 * The generated component inherits the Layout's props and decides per request
 * whether to emit the full page or just the inner frame fragment:
 *
 * - When the current request is the framework re-entering for `frameName`
 *   (see `isFrameRequest`), the component returns its `children` only — the
 *   route emits a fragment that the named Frame can swap in.
 * - Otherwise it renders the Layout. The named `<Frame>` inside that Layout
 *   then re-fetches the same URL with the target header, hitting the
 *   fragment branch above.
 */
export const createPageOrFrame =
  <P extends { children?: RemixNode }>(frameName: FrameName, layout: (handle: Handle<P>) => () => RemixNode) =>
  (handle: Handle<P>) =>
  () => {
    if (isFrameRequest(frameName)) {
      return handle.props.children
    }
    // Use `createElement` directly: `<layout {...handle.props} />` would
    // require TS to reduce `P` through the JSX runtime's variance, which it
    // cannot do for a generic parameter. The runtime semantics are identical.
    return createElement(layout, handle.props)
  }
