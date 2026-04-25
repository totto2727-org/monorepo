/**
 * A single violation produced by a rule.
 *
 * - `rule` identifies the rule that fired.
 * - `message` is shown verbatim to the user/Claude when blocking.
 * - `resolution` describes how to comply with the rule.
 */
export type RuleViolation = {
  readonly rule: string
  readonly message: string
  readonly resolution: string
}

/**
 * A bash-command rule. Each rule inspects the raw command string and returns
 * a violation when it should be blocked, or `null` otherwise.
 *
 * Rules are independent: they own their own parsing strategy (regex, shell
 * tokenization, flag walking) and do not rely on each other.
 */
export type Rule = {
  readonly name: string
  readonly check: (command: string) => RuleViolation | null
}
