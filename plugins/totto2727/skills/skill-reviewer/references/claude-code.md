# Claude Code-Specific Evaluation Categories

Additional evaluation for skills used in the Claude Code environment.
In addition to the general evaluation (G1-G7), the following CC1-CC4 are implemented.

In the review summary, each category is displayed as `CC1`, `CC2`, `CC3`, `CC4`.

---

## CC1: Claude Code-Specific Frontmatter

Whether Claude Code-specific frontmatter fields are used appropriately.

**Check Items:**

- `argument-hint`: Whether completion hints are set for skills with arguments.
- `disable-model-invocation`: Whether it is appropriately set to `true` for skills with side effects.
- `user-invocable`: Whether it is appropriately set to `false` for background knowledge skills.
- `allowed-tools`: Whether it is restricted to the minimum necessary tools (omitted = inherits all tools).
- `model`: Whether a specific model is specified when necessary.
- `context: fork`: Whether sub-agent execution is appropriately specified for heavy processes.
- `agent`: Whether the agent type is appropriate when forked.
- `hooks`: Whether in-skill hooks are defined when necessary.

**Contradiction Checks:**

- `disable-model-invocation: true` + `user-invocable: false` → Nobody can invoke it.
- `context: fork` + guideline-only skill → The sub-agent will wander.

**Claude Code-Specific Anti-pattern:**

- Including custom fields (other than metadata) in frontmatter → Ignored by Claude Code. Describe them in the body markdown.

**Score Criteria:**

- A: Necessary fields are set appropriately with no contradictions.
- B: Generally appropriate but some room for optimization.
- C: Important fields are not set.
- D: Contradictory settings exist.

---

## CC2: Execution Pattern — Appropriate Execution Method

Whether the execution pattern matches the nature of the skill.

| Pattern | Application Scenario | Notes |
|---|---|---|
| Inline (default) | Guideline type, short tasks | No special configuration needed |
| Fork (`context: fork`) | Heavy processing, large output | Requires a clear task. Don't use for guideline-only skills |
| Manual only (`disable-model-invocation: true`) | Has side effects (git push, etc.) | Only invocable via `/name` |

**Score Criteria:**

- A: The optimal pattern for the skill's nature is selected.
- B: It works but is not optimal.
- C: The pattern selection is inappropriate and may cause issues.
- D: Contradictory settings (e.g., fork + guideline only).

---

## CC3: Dynamic Features — Arguments and Context

Whether Claude Code-specific dynamic features are used effectively.

**Argument Substitution:**

- Usage of `$ARGUMENTS` (all arguments), `$0` (first argument), `$1` (second argument).
- If `$ARGUMENTS` is not used in the body, it is automatically appended to the end.
- Whether `argument-hint` is set.
- Whether unnecessary `argument-hint` is set when arguments are not used.

**Dynamic Context `!`command``:**

- Is there information that should be obtained via shell command before loading the skill?
  - Examples: `!`git branch --show-current``, `!`git log --oneline -5``
- Whether unnecessarily heavy commands are included in the dynamic context.

**Score Criteria:**

- A: Dynamic features are used effectively.
- B: Basic usage exists but room for improvement.
- C: Not used in scenarios where they should be.
- D: Used incorrectly.

---

## CC4: allowed-tools Design — Principle of Least Privilege

Whether tool access is appropriately restricted.

**Check Items:**

- If omitted: Whether inheriting all tools is intentional.
- If specified: Whether only the minimum necessary tools are listed.
- If Bash is included: Whether there is a valid reason (script execution, etc.).
- Unspecified for skills performing heavy processing: Risk of unintended tool usage.

**Score Criteria:**

- A: The principle of least privilege is followed.
- B: Generally appropriate but includes excessive tools.
- C: Restrictions are not considered.
- D: Settings that pose security concerns.