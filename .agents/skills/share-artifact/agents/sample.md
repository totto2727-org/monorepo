# agent-marketplace

## Repository structure

```text
plugins/  Distributable plugins
```

## Development commands

### Execution rules

- Run commands from the repository root.
- Enter the pinned environment with `nix develop` before running Vite+ commands.
- Keep secrets out of distributed skills and examples.

### Standard tasks

- `vp check`: Run repository formatting and validation checks.

## Architecture

### Plugins

- Each plugin owns its distributable skills.

### Skills

- Keep guidance project-independent.

## Development tools

- **Vite+**: Runs repository tasks.

## Package-specific rules

- Package-specific AGENTS files supplement the root document.

## Task-specific documentation

- When changing README artifact guidance: [README guidance](../readme/spec.md).
