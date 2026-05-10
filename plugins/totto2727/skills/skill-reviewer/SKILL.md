---
name: skill-reviewer
description: |
  Performs quality review and improvement suggestions for skills (SKILL.md).
  Covers frontmatter validation, description quality, body composition, testing strategy, and anti-pattern detection.
  Triggered by "skill review", "SKILL.md check", "skill quality check", "skill improvement".
  Do NOT use for: creating new skills (use skill-creator), executing or invoking skills.
argument-hint: '[path/to/SKILL.md]'
metadata:
  author: totto2727
  version: 1.0.0
---

# Skill Reviewer — Skill Quality Review & Improvement Suggestions

Use Case Category: **Workflow Automation**
Design Pattern: **Sequential Workflow** (Step 1→2→3→4 sequential execution)

Performs systematic quality review of skills (SKILL.md) and provides improvement suggestions.
Conforms to Anthropic official "The Complete Guide to Building Skills for Claude" (2026-03).

## Basic Policy

- Review results are presented as **scores (A/B/C/D) per evaluation category**
- **Concrete improvement suggestions** are provided for each category
- Evaluation is clearly separated into **general evaluation** (applicable to all Agents) and **Platform-specific evaluation**
- First, read the full content of the target SKILL.md

---

## Review Procedure

### Step 1: Load the Target Skill

1. Read the full content of the user-specified skill's SKILL.md
2. Check the file structure within the same directory (scripts/, references/, assets/, examples/)
3. Check the list of other skills in the same project and evaluate overlap risk with each description
   - Load the frontmatter of all SKILL.md files in the skills directory

### Step 2: Perform General Evaluation

Perform the following evaluation categories (G1-G7) in order.

### Step 3: Perform Platform-Specific Evaluation

**Confirm the target Platform with the user.** Do not guess.
Based on the response, load the relevant Platform-specific evaluation from `references/` and execute it.
Refer to the table in the Platform section and load the relevant file.
If supporting multiple Platforms, perform each evaluation.

### Step 4: Output Review Summary

List all category scores and improvement suggestions in a table format.

---

## General Evaluation Categories (Applicable to all Agents)

### G1: Frontmatter — Structural Validity

Verify that the YAML frontmatter conforms to the specification.

**Mandatory Checks:**

- `name` exists and is in kebab-case
- `name` is at most 64 characters
- `name` does not contain "claude" / "anthropic" (reserved words)
- `description` exists and is not empty
- `description` is within 1024 characters
- Properly enclosed with `---` delimiters
- No XML angle brackets `< >` in the frontmatter

**Recommended Checks:**

- `name` matches the folder name
- `SKILL.md` is case-sensitive (`skill.md` ❌ / `SKILL.MD` ❌)
- Folder name is kebab-case (`my-skill` ✅ / `My_Skill` ❌)
- `license` field (for OSS)
- `metadata` includes author / version
- `compatibility` describes environment requirements (if there are dependencies)

**Score Criteria:**

- A: All mandatory cleared + 3+ recommended
- B: All mandatory cleared + 1-2 recommended
- C: All mandatory cleared but no recommended
- D: Violation in mandatory items

### G2: Description Quality — Lifeline of Triggering Accuracy

Description is the sole material for skill trigger decisions. Quality directly impacts this.

**7-Item Checklist:**

| #   | Check                                               | Evaluation Point                                                                   |
| --- | --------------------------------------------------- | ---------------------------------------------------------------------------------- |
| 1   | What: Is it clearly stated what it does?            | Concrete action verbs ("extract, transform, validate") rather than vague verbs ("manage") |
| 2   | When: Is it clearly stated when to use it?          | Description of use cases or context                                                |
| 3   | Does it contain trigger phrases?                    | Phrases the user would actually say                                                |
| 4   | Are the action verbs concrete?                      | "process" → "analyze and convert to CSV"                                          |
| 5   | Is the length appropriate? (within 1024 chars, not too short) | 2-3 sentences covering overview + trigger + exclusion is ideal                     |
| 6   | Is it differentiated from existing skills?          | No overlap in coverage with other skills                                           |
| 7   | Is there a negative trigger?                        | "Do NOT use for: ..." to prevent false triggering                                  |

**Additional Checks:**

- If file types are relevant, are extensions mentioned?
- Are technical terms properly included? (to prevent undertriggering)
- Is the description neither too "pushy" nor too weak?

**Score Criteria:**

- A: 6-7 out of 7 items cleared + additional checks mostly OK
- B: 4-5 out of 7 items cleared
- C: 2-3 out of 7 items cleared
- D: 0-1 out of 7 items cleared

**Debug Support:**
If there are triggering issues, diagnose the description with:

> "When would you use the [skill-name] skill?"

### G3: Body Structure — Clarity and Structure of Instructions

Evaluate whether the SKILL.md body is effectively structured.

**Check Items:**

- Are important instructions placed at the top of the file?
- Is the imperative form used?
- Are instructions concrete and actionable? ("validate properly" ❌ → "verify project name is not empty" ✅)
- Are steps in clear numbered lists?
- Is the output format specified? (templates or examples)
- Are error handling instructions included?
- Are links to reference files (references/) clear?
- Does it exceed 5,000 words (approx. 500 lines)?

**Why Explanation:**
Rather than overusing MUST or NEVER, does it include **reasoning why** it should be done?
A model that understands the reasoning can make better judgments even in edge cases.

**Score Criteria:**

- A: Clear structure, concrete instructions, error handling present, progressive disclosure appropriate
- B: Structure exists but some instructions are vague
- C: Weak structure or abstract instructions
- D: No structure or only vague instructions

### G4: Progressive Disclosure — Information Hierarchy Design

Is the 3-layer structure properly utilized?

| Layer | Content                   | Ideal State                               |
| ----- | ------------------------- | ----------------------------------------- |
| L1    | YAML frontmatter          | Sufficient info for triggering (~100 words) |
| L2    | SKILL.md body             | Core instructions only (ideally under 500 lines) |
| L3    | references/, scripts/     | Detailed information, large references    |

**Check Items:**

- Are detailed API documents etc. embedded directly in SKILL.md?
- Does reference material exceeding 300 lines have a Table of Contents?
- Are deterministic processes like validation separated into scripts/?
- Is the principle "code is deterministic, language interpretation is non-deterministic" followed?

**Score Criteria:**

- A: 3 layers clearly utilized, body is lean, references/ is appropriate
- B: Mostly good but some information excessively included in L2
- C: Weak awareness of progressive disclosure
- D: All information crammed into SKILL.md

### G5: Use Cases and Patterns — Design Clarity

Is the skill's purpose and design pattern clear?

**Use Case Categories (one of three):**

1. **Document & Asset Creation** — Artifact generation (PDF, code, articles, etc.)
2. **Workflow Automation** — Step-by-step automation
3. **MCP Enhancement** — MCP tools + workflow knowledge

**Design Patterns (one of five):**

1. Sequential Workflow — Ordered processing, step dependencies, validation
2. Multi-Service Coordination — Multiple service coordination, phase separation
3. Iterative Refinement — Generate → Verify → Improve loop
4. Context-aware Selection — Conditional branching, dynamic tool selection
5. Domain Intelligence — Embedded expert knowledge, compliance

**Check Items:**

- Is it clear which category/pattern the skill falls under?
- Does it include pattern-required elements (validation gates, data passing, etc.)?
- Are examples included? (concrete input → output examples)
- Is the skill overly specialized for a specific use case? (generality)
  - Does it function usefully across diverse prompts?
  - Is it not overfitted to specific examples? (should generalize from feedback)

**MCP Enhancement Specific Checks (when applicable to category 3):**

- Are the MCP tool names explicitly stated in the body? (not vague "use MCP tool" but specific names)
- Is behavior on connection errors defined? (MCP server not started, timeout, etc.)
- When coordinating multiple MCP servers, is phase separation clear? (which server to use when)

**Composability Check:**

- Is the design premised on the existence of other skills? (does it not make exclusive assumptions?)
  - Example: Assuming "this skill is the only means of code generation" → NG
- Is it designed not to interfere when coexisting with other skills? (output format conflicts, global state changes, etc.)
- Are responsibility boundaries clear, making role division with adjacent skills inferable?

**Score Criteria:**

- A: Category/pattern clear, examples provided, pattern-specific elements sufficient, composability considered, category-specific checks cleared
- B: Category inferable but not explicitly stated, partial examples, weak composability consideration
- C: Purpose understandable but pattern unclear, coexistence with other skills not considered
- D: Unclear what the skill does

### G6: Testing Strategy — Quality Assurance Design

Is the testing perspective included in the design?

**3 Areas:**

1. **Triggering Test** — Should trigger / Should NOT trigger examples
2. **Functional Test** — Correct output, error handling, edge cases
3. **Performance Test** — Comparison with/without skill

**Check Items:**

- Can test examples corresponding to trigger words in the description be envisioned?
- Is failure behavior defined?
- Does it follow the principle of "first iterate on one difficult task, then skill-ize the successful approach"?

**Score Criteria:**

- A: All 3 areas covered, abundant test examples
- B: 2 areas covered
- C: Only 1 area covered, or weak testing perspective
- D: No testing strategy

### G7: Anti-Patterns — Known Problem Pattern Detection

Detect whether any of the following known anti-patterns apply.

| NG Pattern                                      | Reason                                                                                |
| ----------------------------------------------- | ------------------------------------------------------------------------------------- |
| SKILL.md over 5,000 words                       | Increased loading cost, degraded response quality                                     |
| Vague description                               | No triggering or false triggering                                                     |
| Description over 1024 characters                | Exceeds frontmatter limit                                                             |
| `< >` in description                            | Security violation                                                                    |
| No negative trigger                             | False triggering risk between similar skills                                          |
| README.md exists in the skill folder            | Specification violation                                                               |
| Vague instructions (e.g., "process appropriately") | Model cannot follow correctly                                                         |
| Excessive use of MUST or NEVER                  | Should be replaced by Why explanation                                                 |
| Validation relying solely on language instructions | Should be scriptified                                                                |
| Copying reference file content directly into SKILL.md | Progressive disclosure violation                                                      |
| Over 50 simultaneously active skills            | Context pressure, degraded response quality                                           |
| Contains malware or exploit code                | Violation of Principle of Lack of Surprise. Skills must not act against user expectations |
| Instructions promoting unauthorized access or data exfiltration | Security/safety violation                                              |
| Instructions that act contrary to user intent   | Trust erosion. Skill behavior should be predictable from its description              |

**Score Criteria:**

- A: 0 anti-patterns
- B: 1 (minor)
- C: 2-3
- D: 4 or more, or security-related anti-pattern

---

## Platform-Specific Evaluation

Depending on the Platform where the target skill is used, load the relevant reference file and perform additional evaluation.

| Platform    | Reference File               | Evaluation Categories                                                    |
| ----------- | ----------------------------- | ------------------------------------------------------------------------ |
| Claude Code | `references/claude-code.md`  | CC1-CC4 (dedicated frontmatter, execution patterns, dynamic features, allowed-tools design) |

**Always confirm the target Platform with the user.** Do not guess.
For skills supporting multiple platforms, load all relevant references and evaluate.

---

## Review Summary Output Format

Output review results according to the `templates/review-summary.md` template.
Load the template and replace `?` with the score and `...` with the summary.

---

## Troubleshooting Guide

Also provide the following guide for issues discovered during review.

### No Triggering (Undertriggering)

- Add trigger words to the description
- Include technical terms and keywords
- Make the description slightly "pushy" (also mention possibly relevant use cases)

### Over-triggering (Overtriggering)

- Add negative trigger "Do NOT use for: ..."
- Make the description more specific
- Clearly limit the scope (e.g., "limited to legal PDF documents")

### Instructions Not Followed

- Make instructions more specific ("validate properly" → enumerate specific conditions)
- Move important instructions to the top of the file
- Explain Why instead of MUST
- Script critical validations in scripts/
  - **Code is deterministic, language interpretation is non-deterministic**

### Slow Response or Degraded Quality

- Check if SKILL.md exceeds 5,000 words
- Separate detailed information into references/
- Check the number of simultaneously active skills (20-50 is the recommended upper limit)