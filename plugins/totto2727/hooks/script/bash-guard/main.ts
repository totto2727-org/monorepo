/**
 * PreToolUse hook entrypoint.
 *
 * Reads the hook payload from stdin (JSON), runs each rule against the Bash
 * `command` field, and emits a `permissionDecision: deny` JSON response on
 * stdout when any rule fires. Exits 0 in all cases — Claude Code derives the
 * deny decision from the JSON, not the exit code.
 */

import { rules } from './rules/index.ts'
import type { RuleViolation } from './rules/types.ts'

type HookInput = {
  readonly hook_event_name?: string
  readonly tool_name?: string
  readonly tool_input?: { readonly command?: string }
}

async function readStdin(): Promise<string> {
  const chunks: Uint8Array[] = []
  const reader = Deno.stdin.readable.getReader()
  while (true) {
    const { done, value } = await reader.read()
    if (done) break
    chunks.push(value)
  }
  let total = 0
  for (const c of chunks) total += c.length
  const buf = new Uint8Array(total)
  let off = 0
  for (const c of chunks) {
    buf.set(c, off)
    off += c.length
  }
  return new TextDecoder().decode(buf)
}

function formatReason(violations: readonly RuleViolation[]): string {
  const blocks = violations.map(
    (v) => `[${v.rule}] ${v.message}\n  Resolution: ${v.resolution}`,
  )
  return `Bash command blocked by hook:\n\n${blocks.join('\n\n')}`
}

function evaluate(command: string): RuleViolation[] {
  const out: RuleViolation[] = []
  for (const rule of rules) {
    const v = rule.check(command)
    if (v) out.push(v)
  }
  return out
}

async function main(): Promise<void> {
  const raw = await readStdin()
  const input: HookInput = raw.trim().length === 0 ? {} : JSON.parse(raw)

  if (input.tool_name !== 'Bash') return
  const command = input.tool_input?.command
  if (typeof command !== 'string' || command.length === 0) return

  const violations = evaluate(command)
  if (violations.length === 0) return

  const output = {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: formatReason(violations),
    },
  }
  console.log(JSON.stringify(output))
}

await main()
