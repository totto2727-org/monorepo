/**
 * Entry point for `remix-helper`. Re-exports the `createFrameHelpers` factory
 * (`createFrameHelpers<T extends string>() => FrameHelpers<T>`) for use across
 * Remix v3 consumer projects.
 *
 * @example
 *   import { createFrameHelpers } from 'remix-helper'
 *
 * @module
 */

// oxlint-disable-next-line oxc/no-barrel-file -- intentional barrel re-export of remix-helper modules
export * from './frame-helpers.ts'
