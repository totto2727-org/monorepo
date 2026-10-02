# AGENTS guidance

AGENTS.md gives maintainers and AI agents the repository instructions needed to make changes safely.
Use [documentation-principles](../../documentation-principles/SKILL.md) for content quality.
The [template](template.md) suggests a structure, and the [sample](sample.md) shows a compact repository guide.

## Audience boundary

Include build, test, lint, deploy, architecture, tools, and execution constraints when relevant to repository work.
Consumer installation, usage, public API reference, and license information belong in the [README](../readme/spec.md).
Link to consumer setup instead of maintaining a second copy.

## Suggested sections

- Repository structure when it helps readers find the code they need.
- Development commands, including execution prerequisites and standard tasks.
- Architecture constraints that affect changes.
- Development tools with non-obvious repository-specific usage.
- Package-specific rules not already covered by shared instructions.
- Task-specific documentation with a clear condition for following each link.

Omit empty or redundant sections and adapt the order to the repository.
Commands should say where and in which environment to run them.
Distinguish commands that validate actual behavior from formatting or static checks.
Do not invent a test command merely to fill the outline.

## Task-specific links

Pair each link with the task that makes it relevant, such as “When changing authentication, read the security architecture guide.”
Link to the specific guide or skill instead of requiring all documentation to be read for every change.
Keep detailed explanations at their canonical destination.

## File layout and aliases

The root AGENTS.md owns shared repository instructions.
Package-level AGENTS.md files supplement it with package-specific rules.
When a CLAUDE.md alias is used, keep it as the relative symlink `CLAUDE.md -> AGENTS.md` rather than a separately maintained copy.
The README Development section links to AGENTS.md.

## MoonBit README layout

For MoonBit projects following this convention, keep the physical consumer document in `README.mbt.md` and the relative symlink `README.md -> README.mbt.md`.
Preserve this layout when it is existing project policy.
Record `moon check README.mbt.md` and `moon test README.mbt.md` here when the README contains supported executable MoonBit blocks.
Check examples against the actual package context rather than copying an implementation into a toy fixture and treating that as product verification.
Keep canonical-file, symlink, and validation instructions out of the consumer README.

See the official [literate Markdown documentation](https://docs.moonbitlang.com/en/latest/language/docs.html) and [MoonBit tutorial](https://docs.moonbitlang.com/en/latest/toolchain/moon/tutorial.html) for tool behavior.
The physical-file and symlink layout above is a project convention, not a claim that MoonBit requires it.
