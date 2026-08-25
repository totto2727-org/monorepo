# README specification

This specification defines an end-user-facing project, module, or package entry README. Its companion minimum form is [template.md](template.md), and [sample.md](sample.md) is a concrete rendered output. Read this specification before rendering or extending the template. A nested purpose-specific document may use `README.md` as a directory index without adopting this template when it is not an end-user entrypoint; keep its audience explicit and do not use it to hide content required by the entry README.

## Audience and decision rule

`README.md` serves end users first: it explains what the project does and how to use it. Organize and word it around user value; never distort it for implementation structure, generated-artifact layout, or maintainer convenience. Use the end-user test: if a person who only wants to use the project needs the information, it belongs here. If an AI agent or contributor needs it to modify, build, test, or operate the repository, it belongs in [the AGENTS specification](../agents/spec.md).

A developer can still be an end user of developer tooling. Show the user's tooling task in README, such as invoking an installed skill to improve the user's own project. Put instructions for maintaining the tool's own repository, manifests, generated artifacts, canonical files, or symlinks in AGENTS instead; the subject of the operation, not whether the user writes code, determines the audience.

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

Set `entry_scope` to `root`, `independent`, or `nested`, and set `usage_placement` to `owned` or `linked`, then render the sibling [template.md](template.md) as the end-user README content. Every rendered README contains literal `## Usage` and `## API` headings. `root` is the repository-level consumer entrypoint. `independent` is a nested package, directory, or standalone example that users genuinely acquire, configure, or enter separately. Both require `usage_placement=owned` and use this full minimum order:

1. Title and one-paragraph overview
2. Usage
3. Key features
4. Prerequisites
5. Setup
6. API
7. Development — one short link to `AGENTS.md`, without operational detail
8. License

The full minimum form may be extended with purpose-specific end-user sections, provided the required sections remain in this order, `License` stays the final section, and the extension does not introduce developer, contributor, AI, or internal-operation guidance. A `nested` entry follows the compact form defined in the hierarchy policy below. An extension must not replace the sibling template or sample with an old role-based template path.

## Setup policy

`Setup` is the smallest supported acquisition or installation path that lets an end user use the project from a consumer environment. It contains only acquisition, installation, dependency declarations, imports, and aliases. Prefer a registry or package-manager dependency, an install command, a published release artifact, or a supported project-creation mechanism such as a repository template.

Classify Setup from the product surface instead of forcing every ecosystem into the same commands:

1. For a `library`, keep Setup to the smallest consumer dependency declaration and any required import or alias, such as `npm install`, `moon add`, or `cargo add`. Do not add one-off execution, global installation, or a consumer `flake.nix` merely to fill out the application matrix.
2. For an application surface (`cli`, `agent`, or `gui`), inspect the project's actual published artifacts and document every supported acquisition mode that materially helps users:
   - **Run without installing** — group supported package-manager and language-native commands, such as `npx`, `nix run`, `moonx`, or `go run`, in one bash block.
   - **Install** — group supported persistent commands, such as `npm install --global` (`npm i -g`), `nix profile add` (`nix profile install` is an alias), `moon install`, or a language-specific equivalent, in one bash block.
   - **Nix flake** — show a complete minimal `flake.nix` in one nix block when the project exposes a usable flake package or app.
3. Omit an unsupported mode instead of inventing a package name, registry publication, flake output, or command. Some ecosystems or artifact types do not support direct one-off execution; for example, a Cargo library is acquired with `cargo add`, not forced into a run command. An application Setup still needs at least one real acquisition path unless no setup is genuinely required.

For an application render, pass all three template inputs: `temporary_setup_options`, `persistent_setup_options`, and `consumer_flake_setup`. Use an empty list for an unsupported command mode and an empty mapping for an unsupported consumer flake; the template omits those routes without explanation. Each command option supplies the exact acquisition command in `command`; the template groups each populated command list into one bash block. `consumer_flake_setup` supplies complete `code` in one nix block when present. These alternatives are parallel choices, not sequential numbered steps.

Do not put product output, behavior verification, authentication flows, or repository preparation in `Setup`. A one-off application command may appear in Setup only as a supported acquisition route; put its representative invocation with inputs, output, effects, and authentication in `Usage` or another appropriate end-user section. README contains only current consumer requirements; move implementation history and maintainer details such as build, test, CI, dev-shell, target-selection, or fake-process rationale to `AGENTS.md`. When a library needs no acquisition or installation step, pass an empty `setup_steps` list; when an application needs none, pass empty values for all three application Setup inputs. The template then renders `No setup is required.` instead of inventing a command.

Keep `Prerequisites` limited to requirements a consumer must satisfy before setup, such as a runtime, supported target, account, credential, or external service. Put contributor-only toolchains and repository-development environments in `AGENTS.md`. When no prerequisite exists, pass an empty `prerequisites` list so the template renders `No prerequisites.` instead of inventing one. The overview must state the user outcome, and the usage example must exercise the installed or otherwise acquired public interface. Document user-visible constraints and actionable error behavior in `Usage`, `API`, or a purpose-specific end-user section whenever they are necessary for successful use; do not misclassify them as prerequisites.

## Usage policy

Put dependency declarations, imports, aliases, and other acquisition wiring in `Setup`; they do not satisfy `Usage` by themselves. Every Usage must state a plausible user goal, use representative input, exercise the product's primary public operation, and show a user-relevant outcome or effect. Omit prose that merely restates an obvious command's acquisition or execution semantics, such as saying that `npx`, `moonx`, `nix run`, or `go run` runs once or without installation; retain only user-valued capability, representative input, observable outcome, or an actionable runtime prerequisite or constraint. Usage and API must show one representative acquisition/execution route per user goal; never duplicate the same example for `go run`, `nix run`, and an installed command. Reject constructor-only, initialization-only, identifier round-trip, and default-field inspection examples even when they produce observable output or assertions; those are interface smoke tests, not real use cases. Classify Usage by product surface and set the template's `usage_surface` to exactly one of the following values:

1. `library` — show a small public API code example that demonstrates a real use case and an observable return value, assertion, state change, or effect. Each `usage_examples` entry states its user goal in `summary`, then demonstrates it in `code`. For a multi-package root with no single aggregate operation, pass an empty `usage_examples` list and populate `usage_links` with a balanced direct link to every package-owned `#usage`; each link's `summary` states that package's user goal and outcome. Do not present one arbitrary package example as the whole module's primary operation. Otherwise pass an empty `usage_links` list. When inline code would be misleading or too large, leave both lists empty and set `usage_guide.title`, `usage_guide.path`, and `usage_guide.summary` to link directly to a concrete runnable or checked example. An interface-only library may use this fallback to explain its role and link directly to a concrete implementation's Usage section only when the linked example demonstrates real integration under the same goal, input, operation, and outcome requirements.
2. `cli` — show one representative command and its expected stdout, stderr, file, or state result. A command without its expected result does not satisfy Usage; do not repeat the same result for each Setup route.
3. `agent` — for an installed coding-agent skill or plugin, show a concrete post-install prompt that states the user's goal and a representative expected user-facing output or effect. A prompt that only installs, regenerates, or maintains the tool itself does not satisfy Usage.
4. `gui` — show a current real screenshot or image of the primary user-visible state, followed by a short description of the interaction and its result. A mock, concept image, or stale screenshot does not satisfy Usage.

Reject any other surface. The direct example-link fallback applies only to `library`; reject a generic package page, project homepage, or API reference as the Usage destination for any surface.

## Entry README hierarchy policy

In a repository with root, module, or package entry READMEs, keep common Prerequisites, Setup, Development, and License at the repository root. A multi-package root with no single aggregate operation uses the balanced `usage_links` form above and links directly to every package-owned Usage instead of favoring one package.

Set `entry_scope=nested` for a directory or package README that shares the root consumer flow. Use `usage_placement=owned` when it owns a concise inline Usage that is package-specific, meaningful, observable, and not duplicated at root. Use the literal `## Usage` heading and the same surface-specific real-use requirements as a root example. Use `usage_placement=linked` with `usage_guide` only for a direct link to a concrete, relevant Usage when the package does not own inline Usage. The compact form otherwise contains only the title, that directory or package's distinct role, its uniquely owned API, and the required artifact-provenance footer.

Do not create or keep a nested README unless that path has both distinct user-meaningful Usage, whether owned or directly linked, and an owned API worth documenting. Move reference-only detail to a normal documentation guide instead. MoonBit compilation or doctest convenience is never a reason to keep a README; do not add permanent test code, packages, or manifests solely for documentation validation.

Set `entry_scope=independent` and `usage_placement=owned` to repeat the full form only when the nested package, directory, or standalone example is independently acquired or configured, or is a genuinely distinct consumer entrypoint with its own Usage and Setup. Do not create both a root README and `src/README.md` when their consumer meaning would be identical.

Never duplicate commands, examples, feature lists, API prose, Development links, or License text across the README hierarchy. Keep each detail in one source of truth at the nearest owning entrypoint, and use direct relative links from other READMEs. The root may briefly summarize and navigate to package-owned APIs and Usage, while a nested README may own a distinct inline example or link to root Usage or another concrete runnable example; none may copy another entrypoint's source text.

## Executable MoonBit example validation

Authors and reviewers must validate every executable MoonBit README example with a command that actually compiles or tests that exact rendered artifact against the dependency or current-source context it claims. Record the artifact path, command, dependency or source context, and output in the validation fixture and handoff. A successful `moon check README.mbt.md` or similar command that reports `no work to do` is not evidence because it did not compile the example; select a command and package context whose output proves that the artifact participated in the work.

Put imports in the proper package manifest or supported frontmatter dependency metadata. Never place an `import` declaration inside an `mbt check` block to make a README compile. When Setup shows a dependency version, validate against that same version. Alternatively, validate against the current source tree through an existing meaningful test/example context, or through a disposable external/temp fixture or supported direct artifact check whose imports resolve the current implementation without changing consumer Setup. Do not create permanent test-only scaffolding solely to compile or execute a README.

Compilation or doctest convenience never justifies a duplicate `src/README.mbt.md` or another semantically identical README. Keep the one user-owned artifact and supply compiler context only through an existing meaningful test/example or a disposable fixture/direct check; do not add permanent documentation-only package configuration.

After `License` in the full form, or after `API` in the compact `nested` form, append this exact artifact-specific provenance footer without a heading:

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

Do not add AI rules such as “never use npx” to README; move them to `AGENTS.md` and retain only the Development link. Do not put repository cloning, developer-shell entry, dependency synchronization, code generation, build, test, lint, CI, publishing, or contributor setup commands in README; those commands fail the end-user test and belong in `AGENTS.md`. Do not expose canonical source-file selection, symlink layout, template rendering, or other generated-artifact maintenance in README; those are maintainer rules for `AGENTS.md`. Do not add repository architecture or directory structure to README merely because it is useful to developers. Do not replace meaningful API usage with a symbol dump, an incomplete shortlist, a constructor or default-value smoke test, or a bare link to a non-API package page. Do not move user-facing CLI reference material or required runtime constraints into `AGENTS.md`.
