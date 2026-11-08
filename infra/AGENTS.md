# Infrastructure Development Guide

Common tools, settings, and deployment workflow for infrastructure projects in this monorepo.

## Quick Reference

- **Main coding standards**: See @docs/coding-rules.md
- **Lint rules**: See @docs/ultracite.md
- **Repository structure**: See @CLAUDE.md

## Infrastructure Projects

### AWS (`infra/aws/`)

AWS Infrastructure as Code using Pulumi:

- IAM Identity Center management
- OIDC providers
- Organization settings

### Cloudflare (`infra/cloudflare/`)

Cloudflare Zero Trust configuration using Pulumi:

- Access applications
- Access policies
- Native passkey identity provider
- Workers deployment

### GitHub (`infra/github/`)

GitHub repository management using Pulumi:

- `totto2727-org` repositories, with owner-specific Providers for additional organizations
- Merge settings and additive default-branch rulesets
- Per-repository required CI checks and merge queue compatibility
- No organization settings, membership, teams, or upstream repositories

For GitHub token permissions and ESC configuration, see the [GitHub setup guide](./github/README.md).
Do not delete existing protection rules or change repository visibility when adopting repositories.

## Common Tools

### Infrastructure as Code

- **Pulumi**: Infrastructure as Code framework
  - TypeScript-based configuration
  - State management via Pulumi Cloud
  - Stack references for cross-project dependencies

### Pulumi ESC (Environments, Secrets, and Configuration)

- **AWS**: OIDC authentication with IAM roles
- **Cloudflare**: API token management
- **GitHub**: GitHub App installation tokens through ESC `gh-login`

## Configuration Files

### Pulumi Stack Configuration

```yaml
# Pulumi.{stack}.yaml
environment:
  - aws/production # or cloudflare/production or github/production
```

### TypeScript Configuration

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist"
  }
}
```

## Deployment Workflow

See @infra/README.md for detailed deployment procedures.

## Reference Examples

- AWS IAM Identity Center: [@infra/aws/src/identify-store.ts](./aws/src/identify-store.ts)
- Cloudflare Access: [@infra/cloudflare/src/identity-provider.ts](./cloudflare/src/identity-provider.ts)
