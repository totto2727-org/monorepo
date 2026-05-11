import type { Handle, Props, RemixNode } from 'remix/ui'
import { createElement } from 'remix/ui'

type FrameLinkProps<T extends string> = Props<'a'> & {
  href: string
  'rmx-target': T
  'rmx-src': string
}

interface FrameHelpers<T extends string> {
  readonly FrameLink: (handle: Handle<FrameLinkProps<T>>) => () => RemixNode
  readonly createPageOrFrame: <P extends { children?: RemixNode }>(
    frame: T,
    layout: (handle: Handle<P>) => () => RemixNode,
  ) => (request: Request) => (handle: Handle<P>) => () => RemixNode
  readonly isFrameRequest: (request: Request, frame: T) => boolean
}

// factory。`T extends string` で string literal union を generics 引数に直接受け取る。
// ランタイム引数は不要 (型のみの specialization)。R-5 で型関数 InferFrameName 廃止 + R-6 で
// FrameLink 統合。U-3 で hono/context-storage への依存を完全排除、Request を直接受け取る
// signature に確定。consumer は `c.req.raw` を adapter 経由で渡す。
export const createFrameHelpers = <T extends string>(): FrameHelpers<T> => ({
  FrameLink: (handle) => () => {
    const { children, ...rest } = handle.props
    return createElement('a', rest, children)
  },

  createPageOrFrame: (frame, layout) => (request) => (handle) => () => {
    if (request.headers.get('x-remix-target') === frame) {
      return handle.props.children
    }
    // `createElement` 直接呼び出し。`<layout {...handle.props} />` は
    // TS が generic `P` を JSX runtime の variance で reduce できないため
    // 構文として成立しない (元実装コメント継承)。
    return createElement(layout, handle.props)
  },

  isFrameRequest: (request, frame) => request.headers.get('x-remix-target') === frame,
})
