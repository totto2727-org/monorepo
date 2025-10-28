# Infrastructure Deployment Guide

This guide covers the deployment workflow for AWS and Cloudflare infrastructure using Pulumi.

## Prerequisites

- Pulumi CLI installed
- AWS CLI configured
- Cloudflare API token configured in Pulumi ESC

## Deployment Order

**IMPORTANT**: Infrastructure must be deployed in the following order due to dependencies:

1. **AWS Infrastructure** (`infra/aws/`)
2. **Cloudflare Infrastructure** (`infra/cloudflare/`)

## Deployment Workflow

### 1. Deploy AWS Infrastructure

Navigate to the AWS infrastructure directory:

```bash
cd infra/aws
```

Deploy the stack:

```bash
pulumi up
```

This will create:

- IAM Identity Center resources
- SAML/OIDC providers
- Organization settings
- Application integration resources

### 2. Update Cloudflare SAML Configuration

After AWS deployment completes, update the Cloudflare SAML identity provider configuration:

1. Open [infra/cloudflare/src/identity-provider.ts](./cloudflare/src/identity-provider.ts)
2. Update the `awsSaml` configuration with new values from AWS IAM Identity Center:
   - `idpPublicCerts`: SAML certificate from AWS
   - `issuerUrl`: SAML metadata URL
   - `ssoTargetUrl`: SAML assertion URL

These values can be obtained from:

- AWS Console → IAM Identity Center → Applications → Application details
- Or from Pulumi outputs if exported

### 3. Deploy Cloudflare Infrastructure

Navigate to the Cloudflare infrastructure directory:

```bash
cd infra/cloudflare
```

Deploy the stack:

```bash
pulumi up
```

This will create:

- Zero Trust Access applications
- Access policies
- Identity providers (including AWS SAML)
- Workers configurations

## Configuration Management

### Pulumi ESC

Both projects use Pulumi ESC for secrets and configuration management:

- **AWS**: OIDC authentication via IAM roles
- **Cloudflare**: API token stored in Pulumi ESC

Configuration is defined in:

- `aws/production` environment (for AWS)
- `cloudflare/production` environment (for Cloudflare)

### Stack References

Cloudflare infrastructure references AWS outputs via Stack References:

```typescript
const awsStackRef = new pulumi.StackReference(`totto2727/aws/${stack}`)
export const awsMcpGroupID = awsStackRef.requireOutput("mcpGroupId")
```
