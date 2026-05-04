/**
 * Helpers for composing Vite+ task `input` arrays.
 *
 * @example
 * ```ts
 * import { defineTaskInputFromOutput } from "@totto2727/fp/vite";
 *
 * const inputs = defineTaskInputFromOutput({
 *   setup: {
 *     cloudflare: [".wrangler/**", "worker-configuration.d.ts"],
 *     kysely: ["src/feature/db/generated.ts"],
 *   },
 * });
 *
 * inputs.setup.cloudflare;
 * // readonly [{ auto: true }, "!.wrangler/**", "!worker-configuration.d.ts"]
 *
 * inputs.build;
 * // readonly [{ auto: true }, "!.wrangler/**", "!worker-configuration.d.ts", "!src/feature/db/generated.ts"]
 * ```
 *
 * @module
 */

import { Record as Rec } from 'effect'

/** Marker emitted by Vite+ to enable automatic input tracking. */
export interface AutoInput {
  readonly auto: true
}

/** Prefix a glob with `!` so Vite+ treats it as an exclusion. */
export type NegatedPath<P extends string> = `!${P}`

/** A single Vite+ `input` array element. */
export type TaskInputElement<P extends string> = AutoInput | NegatedPath<P>

/**
 * A single Vite+ `input` array: `[{ auto: true }, ...!negated paths]`.
 *
 * Mutable so it satisfies Vite+'s `Task.input` type.
 */
export type TaskInputArray<P extends string> = TaskInputElement<P>[]

const AUTO_INPUT: AutoInput = { auto: true }

const negatePath = <const P extends string>(path: P): NegatedPath<P> => `!${path}`

/**
 * Build Vite+ task `input` arrays from a per-task list of generated outputs.
 *
 * Repeating identical exclusion globs across `prebuild:*`-style tasks
 * and the consuming `build` task is mechanical and easy to drift; this
 * helper centralises the path lists in one place.
 *
 * Each array under `setup[*]` should hold the *raw* output paths (no
 * leading `!`). The helper returns:
 *
 * - `setup[*]`: `[{ auto: true }, ...negated paths for that single task]`
 *   — wire this into the matching task's `input`.
 * - `build`: `[{ auto: true }, ...all negated paths across every setup]`
 *   — wire this into the consuming `build` task's `input`.
 */
export const defineTaskInputFromOutput = <const S extends Record<string, readonly string[]>>(args: {
  readonly setup: S
}): {
  readonly build: TaskInputArray<S[keyof S][number]>
  readonly setup: Record<keyof S & string, TaskInputArray<S[keyof S][number]>>
} => {
  const toTaskInput = <P extends string>(paths: readonly P[]): TaskInputArray<P> => [
    AUTO_INPUT,
    ...paths.map(negatePath),
  ]
  const setup = Rec.map(toTaskInput)(args.setup)
  const build = toTaskInput(Rec.values(args.setup).flat())
  return { build, setup }
}
