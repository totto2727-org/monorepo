import { getContext } from 'hono/context-storage'

/**
 * Named frames declared in this app.
 *
 * ms-01 段階では Frame ベースの partial swap UI (PageOrFrame) は未採用 (TC-022)。
 * 本ファイルは将来 ms-04 / ms-07 で UI を強化する際の最小骨格として、
 * 名前空間と `isFrameRequest` ヘルパだけを保持する。
 *
 * `frames` は空オブジェクトのまま、PageOrFrame パターンを採用する時点で
 * `content: 'content'` 等のキーを追加する。
 */
export const frames = {} as const

export type FrameName = (typeof frames)[keyof typeof frames]

/**
 * Returns true when the current request is the framework re-entering to fetch
 * the inner content of the given frame. ms-01 では誰も呼ばないが、後続マイル
 * ストーンが PageOrFrame を採用したときに参照する形を予告する。
 *
 * Reads the current Hono context via `hono/context-storage`, so `contextStorage()`
 * must be in the middleware chain.
 */
export const isFrameRequest = (frame: FrameName): boolean => getContext().req.header('x-remix-target') === frame
