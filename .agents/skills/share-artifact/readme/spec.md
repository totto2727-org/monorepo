# README specification

This specification defines an end-user-facing project, module, or package entry README. Its companion minimum form is [template.md](template.md), and [sample.md](sample.md) is a concrete rendered output. Read this specification before rendering or extending the template. A nested purpose-specific document may use `README.md` as a directory index without adopting this template when it is not an end-user entrypoint; keep its audience explicit and do not use it to hide content required by the entry README.

## Audience and decision rule

`README.md` serves end users first: it explains what the project does and how to use it. Use the end-user test: if a person who only wants to use the project needs the information, it belongs here. If an AI agent or contributor needs it to modify, build, test, or operate the repository, it belongs in [the AGENTS specification](../agents/spec.md).

| Content                                                                                                                        | README.md                              | AGENTS.md                              | Decision                                                              |
| ------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------- | -------------------------------------- | --------------------------------------------------------------------- |
| Project overview, user-visible features, usage examples, end-user prerequisites and setup, external documentation, and license | Yes                                    | No                                     | Explain the user outcome and the smallest usable path.                |
| Public API reference and meaningful API usage                                                                                  | Yes                                    | No                                     | Keep the user-facing API entrypoint in README or link its full guide. |
| User-visible targets, required credentials or configuration, constraints, and actionable error behavior                        | Yes                                    | No                                     | Include what an end user needs for successful use.                    |
| Detailed build, test, lint, deploy, CI, task, or contributor commands                                                          | No                                     | Yes                                    | These are developer and AI execution instructions.                    |
| Repository structure, architecture, package management, path aliases, conventions, development tools, and AI constraints       | No                                     | Yes                                    | These govern work on the repository.                                  |
| Full CLI reference                                                                                                             | Inline when concise, otherwise link it | No                                     | Keep the source of truth in user documentation or generated help.     |
| Contribution guidance                                                                                                          | Link to a dedicated guide when present | No                                     | Do not turn the README into a contributor manual.                     |
| A cross-reference needed by both audiences                                                                                     | Brief summary and link                 | Detailed form for its primary audience | Keep one source of truth; do not duplicate the detailed text.         |

## Required output and minimum order

Render the sibling [template.md](template.md) as the project `README.md` unless the MoonBit exception below applies. The minimum form uses this order:

1. Title and one-paragraph overview
2. Usage
3. Key features
4. Prerequisites
5. Setup
6. API
7. Development — one short link to `AGENTS.md`, without operational detail
8. License

The minimum form may be extended with purpose-specific end-user sections, provided the required sections remain in this order, `License` stays the final section, and the extension does not introduce developer, contributor, AI, or internal-operation guidance. An extension must not replace the sibling template or sample with an old role-based template path.

## Setup policy

`Setup` is the smallest supported acquisition or installation path that lets an end user use the project from a consumer environment. Prefer a registry or package-manager dependency, an install command, a published release artifact, or a supported project-creation mechanism such as a repository template. A source checkout and build may appear only when building from source is itself a supported end-user distribution path; include only the steps needed to produce and use the distributed artifact.

Do not satisfy `Setup` with repository preparation such as `git clone`, entering a developer shell, dependency synchronization for contributors, code generation, build verification, tests, lint, CI, or publishing commands. Move that material to `AGENTS.md`. When an end user needs no acquisition or installation step, pass an empty `setup_steps` list so the template renders `No setup is required.` instead of inventing a command.

Keep `Prerequisites` limited to requirements a consumer must satisfy before setup, such as a runtime, supported target, account, credential, or external service. Put contributor-only toolchains and repository-development environments in `AGENTS.md`. When no prerequisite exists, pass an empty `prerequisites` list so the template renders `No prerequisites.` instead of inventing one. The overview must state the user outcome, and the usage example must exercise the installed or otherwise acquired public interface. Document user-visible constraints and actionable error behavior in `Usage`, `API`, or a purpose-specific end-user section whenever they are necessary for successful use; do not misclassify them as prerequisites.

## Usage policy

Put dependency declarations, imports, aliases, and other acquisition wiring in `Setup`; they do not satisfy `Usage` by themselves. Classify Usage by product surface and set the template's `usage_surface` to exactly one of the following values:

1. `library` — show a small public API code example that demonstrates the main feature and an observable return value, assertion, state change, or effect. When inline code would be misleading or too large, pass an empty `usage_examples` list and set `usage_guide.title`, `usage_guide.path`, and `usage_guide.summary` to link directly to a concrete runnable or checked example.
2. `cli` — show an installed command and a representative expected stdout, stderr, file, or state result. A command without its expected result does not satisfy Usage.
3. `gui` — show a current real screenshot or image of the primary user-visible state, followed by a short description of the interaction and its result. A mock, concept image, or stale screenshot does not satisfy Usage.

Reject any other surface. The direct example-link fallback applies only to `library`; reject a generic package page, project homepage, or API reference as the Usage destination for any surface.

After `License`, append this exact artifact-specific provenance footer without a heading:

```markdown
_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._
```

The footer identifies only the sources used to create the current README; it is not a project documentation index.

## API documentation policy

Set the template's `api.mode` to exactly one of the following values after inspecting the public API and its publishing registry:

1. `registry` — use this only when the registry actually renders a maintained, accessible API index, as MoonBit and JSR registries commonly do. Inspect the published page, set `api.registry_name` and `api.registry_url`, link directly to the canonical API index, and do not duplicate the generated API list in README.
2. `inline` — use this when no registry supplies the API index and every meaningful public API can be explained concisely without making README difficult to navigate. Set `api.entries` and document every meaningful public API with its purpose and a representative usage example; do not omit an API merely to shorten the section.
3. `guide` — use this when no registry supplies the API index and complete inline coverage would make README difficult to navigate. Create a detailed guide under `docs/`, set `api.guide_title`, `api.guide_path`, and `api.guide_summary`, then keep only that summary and relative guide link in README.

Reject any other mode, an empty registry URL, a registry package landing page that does not expose the API, an inaccessible or suppressed API index, partial inline coverage, or a guide link whose target does not exist. The API section is required even when its contents are delegated to a registry or `docs/` guide.

## CLI documentation policy

For a command-line project, show an installed command and its representative expected result in `Usage`, then provide a maintained discovery path for the remaining commands and options. Keep a concise complete reference in README, link a detailed end-user guide under `docs/`, or point to generated help with the exact command needed to reach it, such as `tool --help`. Include nested help paths when discovery depends on a subcommand. A full CLI reference is end-user documentation and must never use `AGENTS.md` as its source of truth; `AGENTS.md` contains only repository development and operation instructions.

## Shared content and updates

For shared content, write the detailed version in the document serving the primary audience, then add only a brief summary and relative link in the other document. For example, README may link to `./AGENTS.md#development-commands`; AGENTS may link to `./README.md#setup` for end-user setup.

When updating an existing project:

1. Read its existing `README.md` and `AGENTS.md` first.
2. Classify the proposed content using the table and end-user test.
3. Update only the correct document, preserving its required order.
4. Inspect the public API and registry, then select and fully populate one API documentation mode.
5. When the content serves both audiences, split it using the shared-content link rule.
6. Preserve valid local links and use the sibling [template.md](template.md) and [sample.md](sample.md) as the current authoring references.

## Corrections for common mistakes

Do not add AI rules such as “never use npx” to README; move them to `AGENTS.md` and retain only the Development link. Do not put repository cloning, developer-shell entry, dependency synchronization, code generation, build verification, test, lint, CI, publishing, or contributor setup commands in README; those commands fail the end-user test and belong in `AGENTS.md`, except for the narrow supported source-distribution case in the Setup policy. Do not add repository architecture or directory structure to README merely because it is useful to developers. Do not replace meaningful API usage with a symbol dump, an incomplete shortlist, or a bare link to a non-API package page. Do not move user-facing CLI reference material or required runtime constraints into `AGENTS.md`.

## MoonBit exception

For a MoonBit project, render the sibling [template.md](template.md) to canonical `README.mbt.md`, then make `README.md` a relative symlink: `README.md -> README.mbt.md`. Keep the Markdown and its supported MoonBit code blocks valid for `moon check README.mbt.md` and `moon test README.mbt.md`. Do not maintain a second independently authored README.

This layout follows MoonBit’s official literate Markdown documentation: <https://docs.moonbitlang.com/en/latest/language/docs.html>. The relative symlink layout is documented in the official MoonBit tutorial: <https://docs.moonbitlang.com/en/latest/toolchain/moon/tutorial.html>.
