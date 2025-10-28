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
- SAML/OIDC providers
- Organization settings
- Application integration

### Cloudflare (`infra/cloudflare/`)

Cloudflare Zero Trust configuration using Pulumi:

- Access applications
- Access policies
- Identity providers
- Workers deployment

## Common Tools

### Infrastructure as Code

- **Pulumi**: Infrastructure as Code framework
  - TypeScript-based configuration
  - State management via Pulumi Cloud
  - Stack references for cross-project dependencies

### Pulumi ESC (Environments, Secrets, and Configuration)

- **AWS**: OIDC authentication with IAM roles
- **Cloudflare**: API token management

## Configuration Files

### Pulumi Stack Configuration

```yaml
# Pulumi.{stack}.yaml
environment:
  - aws/production # or cloudflare/production
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
