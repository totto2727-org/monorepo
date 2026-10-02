# README guidance

An entry README helps consumers understand what a project does and use its public surface.
Use [documentation-principles](../../documentation-principles/SKILL.md) for content quality.
The [template](template.md) sketches the overall structure, and the [sample](sample.md) illustrates a library README.

## Consumer and maintainer boundary

Keep consumer installation, usage, public reference, and license information in the README.
Put repository development commands, architecture, contributor toolchains, and AI instructions in [AGENTS.md](../agents/spec.md).
Someone using a development tool is a consumer, not necessarily a maintainer of that tool.
The README's Development section links to maintenance instructions instead of duplicating them.

## Suggested structure

1. Project title and a short overview.
2. Usage showing a public operation and its result.
3. Key features that help readers choose the project.
4. Prerequisites needed by consumers.
5. Setup for acquiring or configuring the project.
6. API or another clearly named public reference.
7. Development link to AGENTS.md.
8. License.

Omit sections that add no useful information and add consumer-specific sections where needed.
A directory index does not need the full consumer entrypoint structure.

## Entry hierarchy

The root README owns shared prerequisites, setup, development links, and license information.
Shared prerequisites are requirements of the default or common route, not the union of every optional host's requirements.
Keep host-specific blockers in the corresponding guide before the command that needs them.
A separately acquired or configured package needs its own consumer entrypoint.
A nested package sharing root setup can focus on its overview, usage, and API, linking to shared setup rather than repeating it.
A multi-package root can link directly to package usage examples.
When delegating usage, link to a concrete example or usage section rather than a package landing page or API index.
When a documentation site owns the consumer guide and reference, link directly to those pages rather than maintaining another full guide in the package README.
Keep the package overview and the information needed to choose the right destination.

## Usage

Choose examples that match the public surface:

- Library: A short example calling the public API and showing the result.
- CLI: A command and its expected output or observable effect.
- Agent skill: A representative request and the expected assistance or artifact.
- GUI: A screenshot or interaction sequence and the resulting state.

Keep dependency installation and project configuration in Setup.
Include imports in an example when readers need them to understand or run it independently.
Do not present an illustrative sample as evidence that a real product works.

## Prerequisites and setup

List consumer requirements, not tools used only to maintain the repository.
For libraries, show the dependency declaration or installation command and necessary imports or aliases.
For applications and tools, show the supported acquisition options as alternatives:

- Run without installing.
- Install persistently.
- Consume through a Nix flake, when supported.

Use headings rather than numbered steps for mutually alternative setup routes.
Show enough configuration to use a supported flake route, not a fragment that leaves essential wiring unexplained.
Omit unsupported options and state that no setup is needed when that helps the reader.
Do not put runtime demonstrations or repository development shells in acquisition instructions.

## Public reference

Provide a concise inline reference or link directly to a maintained API index or consumer guide.
A registry landing page without API documentation is not an API reference.
For a CLI, an exact generated-help command and relevant subcommand help paths can provide the reference.
Do not send consumers to AGENTS.md for public CLI usage.

## MoonBit projects

The existing physical README convention and maintainer validation commands are described in [MoonBit README layout](../agents/spec.md#moonbit-readme-layout).
Keep those maintenance details out of the consumer README.
