# agent-marketplace

## Repository structure

```text
plugins/  Distributable plugins
```

## Development commands

### Execution rules

- Run commands from the repository root.
- Use vp for project tasks.

### Standard tasks

- `vp run check` — Run checks.
- `vp run test` — Run tests.

## Architecture

### Plugins

- Each plugin owns its distributable skills.

### Skills

- Keep guidance project-independent.

## Development tools

- **Vite+**: Runs repository tasks.
- **MoonBit**: Checks MoonBit packages.

## Package-specific rules

- Package-specific AGENTS files supplement the root document.

## MoonBit README maintenance

Keep the canonical end-user content in the physical `README.mbt.md` file and maintain `README.md` as the relative symlink `README.md -> README.mbt.md`. Validate supported MoonBit blocks with `moon check README.mbt.md` and `moon test README.mbt.md`. Never render canonical-file or symlink-maintenance instructions into the end-user README.

_This AGENTS.md was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [AGENTS template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/agents/template.md)._
