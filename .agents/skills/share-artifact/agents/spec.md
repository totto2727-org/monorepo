# AGENTS specification

This specification defines the AI-agent and developer-facing document. Its companion minimum form is [template.md](template.md), and [sample.md](sample.md) is a concrete rendered output. Read this specification before rendering or extending the template.

## Audience and decision rule

`AGENTS.md` tells AI agents and developers how to work correctly in the repository. Use the AI-agent test: if an agent needs the information to modify, build, test, or operate the project safely, it belongs here. Information that an end user needs to understand, install, or use the project belongs in [the README specification](../readme/spec.md).

| Content                                                                                                        | README.md              | AGENTS.md                                     | Decision                                         |
| -------------------------------------------------------------------------------------------------------------- | ---------------------- | --------------------------------------------- | ------------------------------------------------ |
| End-user overview, usage, features, prerequisites, setup, external user documentation, and license             | Yes                    | No                                            | Keep the user-facing explanation in README.      |
| Build, test, lint, format, deploy, CI, task, package-targeting, and contributor commands                       | No                     | Yes                                           | Give AI agents the complete executable guidance. |
| Repository structure, architecture, package management, aliases, conventions, tools, and execution constraints | No                     | Yes                                           | These are the repository’s operating rules.      |
| Repository development and operation command reference                                                         | No                     | Yes                                           | AGENTS is the canonical developer reference.     |
| Shared setup or cross-reference                                                                                | Brief summary and link | Brief link to the end-user source when needed | Keep detailed content with its primary audience. |

## Required output and minimum order

Render the sibling [template.md](template.md) as `AGENTS.md`. The minimum form uses this order:

1. Project title
2. Repository structure
3. Development commands, including execution rules and standard tasks
4. Architecture
5. Development tools
6. Package-specific rules when applicable
7. MoonBit README maintenance when applicable
8. Artifact-specific provenance footer

The minimum form may be extended with repository-specific AI and developer sections, provided the required sections stay ordered, the extension does not become an end-user getting-started guide, and it retains the sibling [template.md](template.md) and [sample.md](sample.md) as the current authoring references.

Render consecutive single-paragraph bullet items as a tight list without blank lines between items. Keep one blank line before and after the list so adjacent headings and paragraphs remain distinct.

End the file with this exact provenance footer without a heading:

```markdown
_This AGENTS.md was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [AGENTS template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/agents/template.md)._
```

The footer identifies only the sources used to create the current `AGENTS.md`; it is not a project documentation index.

## Root, package, and alias rules

The repository-root `AGENTS.md` is the canonical shared AI context. Create a package-level `AGENTS.md` only when that package has unique AI or developer rules not already covered by the root file; it supplements the root instead of duplicating it.

`CLAUDE.md -> AGENTS.md` is a relative symlink alias for the same canonical content. Never create a separate `CLAUDE.md` template or allow `CLAUDE.md` and `AGENTS.md` to diverge.

## Shared content and updates

For content serving both audiences, keep the detailed version with its primary audience and add a short relative link elsewhere. For example, AGENTS may link to `./README.md#setup` for consumer installation, while README may link to `./AGENTS.md#development-commands` for repository development commands. End-user CLI commands and generated help remain governed by the README specification; AGENTS documents only commands for modifying, building, testing, or operating the repository.

When updating an existing project:

1. Read its existing `README.md`, root `AGENTS.md`, and relevant package `AGENTS.md` files first.
2. Classify the proposed content with the table and AI-agent test.
3. Update the root or the unique package document without duplicating shared rules.
4. Split cross-audience content with the shared-content link rule.
5. Preserve valid local links, preserve the `CLAUDE.md -> AGENTS.md` alias, and use the sibling [template.md](template.md) and [sample.md](sample.md) as the current references.

## Corrections for common mistakes

Do not place an end-user project description, installation walkthrough, marketing highlights, or license text in AGENTS; move it to README. Do not create divergent `CLAUDE.md` content; make it the `AGENTS.md` alias. Do not create a package AGENTS file that repeats the root document; add one only for unique local rules. Do not conceal build or test commands in README: they belong in AGENTS under Development commands.

## MoonBit README maintenance

For MoonBit projects, keep the canonical end-user content in the physical `README.mbt.md` file and maintain `README.md` as the relative symlink `README.md -> README.mbt.md`. Validate supported MoonBit blocks with `moon check README.mbt.md` and `moon test README.mbt.md`. This is maintainer guidance for AI agents and developers; never render canonical-file or symlink-maintenance instructions into the end-user README.

This layout follows MoonBit’s official literate Markdown documentation: <https://docs.moonbitlang.com/en/latest/language/docs.html>. The relative symlink layout is documented in the official MoonBit tutorial: <https://docs.moonbitlang.com/en/latest/toolchain/moon/tutorial.html>.
