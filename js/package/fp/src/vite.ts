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

import { Record } from 'effect'

export type TaskInputWithAuto = [{ auto: true }, ...string[]]

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
export const defineTaskInputFromOutput = <
  const T extends Record<PropertyKey, string[]>,
  // oxlint-disable-next-line no-unnecessary-type-parameters -- use parameter and type assertion
  U extends Record<keyof T, [{ auto: true }, ...string[]]>,
>(args: {
  setup: T
}): {
  build: TaskInputWithAuto
  setup: U
} => {
  const toTaskInput = (paths: string[]) => [{ auto: true }, ...paths.map((v) => `!${v}`)] satisfies TaskInputWithAuto
  // oxlint-disable-next-line no-unsafe-type-assertion -- type assertion is necessary to satisfy the return type
  const setup = Record.map(toTaskInput)(args.setup) as U
  const build = toTaskInput(Record.values(args.setup).flat())
  return { build, setup }
}
