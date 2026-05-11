/**
 * Entry point for `effect-hono`. Re-exports the `Env` namespace plus the
 * dynamic logger / disposable runtime utilities so consumers can pull
 * everything from a single import path.
 *
 * @example
 *   import { Env, dynamicLoggerLayer, makeDisposableRuntime } from 'effect-hono'
 *
 * @module
 */

// oxlint-disable-next-line oxc/no-barrel-file -- intentional barrel re-export of effect-hono modules
export * as Env from './env.ts'
// oxlint-disable-next-line oxc/no-barrel-file -- intentional barrel re-export of effect-hono modules
export * from './logger.ts'
// oxlint-disable-next-line oxc/no-barrel-file -- intentional barrel re-export of effect-hono modules
export * from './runtime.ts'
