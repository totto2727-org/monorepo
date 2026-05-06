import { getContext } from 'hono/context-storage'

/**
 * Named frames declared in this app. Each entry pairs the JSX `<Frame name>`
 * with the `<a rmx-target>` value so the two stay in lock-step.
 *
 * The router itself is defined in `app.tsx` against Hono — this module exists
 * solely to give `<Frame>` / `<FrameLink rmx-target>` / `isFrameRequest()` a
 * single source of truth for frame names.
 *
 * ms-01 段階では Frame は宣言のみで未使用。ms-04 / ms-07 で UI を強化する際に活用する。
 */
export const frames = {
  content: 'content',
} as const

export type FrameName = (typeof frames)[keyof typeof frames]

/**
 * Returns true when the current request is the framework re-entering to fetch
 * the inner content of the given frame. In that case the route should respond
 * with just the page fragment so only that named frame is updated and the
 * surrounding shell stays mounted.
 *
 * Reads the current Hono context via `hono/context-storage`, so `contextStorage()`
 * must be in the middleware chain.
 */
export const isFrameRequest = (frame: FrameName): boolean => getContext().req.header('x-remix-target') === frame
