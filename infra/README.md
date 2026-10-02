# Infrastructure Deployment Guide

This guide covers the deployment workflow for AWS and Cloudflare infrastructure using Pulumi.

## Prerequisites

- Pulumi CLI installed
  - `brew install pulumi`
- An existing AWS session with IAM provider-and-role management permissions for the initial bootstrap
- Access to the Pulumi organization, stacks, and ESC environments
- Cloudflare API token configured in Pulumi ESC

## Manual Setup Before Deployment

### AWS: Pulumi Authentication and Authorization

Pulumi ESC exchanges an OIDC token for temporary AWS credentials using `fn::open::aws-login`.
Its OIDC provider and IAM role must already exist before ESC can authenticate, so the first registration requires an existing AWS session with IAM provider-and-role management permissions.
Do not depend on the uncreated Pulumi role to create itself.

Register or reuse the following resources in the AWS account targeted by the stack:

| Resource                   | Configuration matching the current IaC                                                               |
| -------------------------- | ---------------------------------------------------------------------------------------------------- |
| IAM OIDC identity provider | Provider URL `https://api.pulumi.com/oidc`, audience `aws:totto2727`                                 |
| IAM deployment role        | Production role name `iac-prod-pulumi`, with the OIDC provider ARN as its federated principal        |
| Role trust policy          | Allow `sts:AssumeRoleWithWebIdentity` and require `api.pulumi.com/oidc:aud` to equal `aws:totto2727` |
| Role permission policies   | Match the current deployment role configuration in [provider.ts](./aws/src/provider.ts)              |

The current role configuration attaches `AWSOrganizationsFullAccess`, `AWSSSODirectoryAdministrator`, `AWSSSOMasterAccountAdministrator`, `AmazonS3FullAccess`, and `IAMFullAccess`.
This is the existing policy set, not a verified least-privilege policy.
The current trust policy checks the audience only and does not restrict access to a particular ESC environment.
If environment-specific trust is required, review the actual OIDC subject and configure matching ESC `subjectAttributes` and IAM `sub` conditions in the IaC before adopting the resources.
Do not assume an environment's name alone is its OIDC subject.

Create or update the `aws/production` ESC environment using the [AWS configuration example](./aws/README.md).
Set `oidc.roleArn` to the existing deployment role's ARN before opening the environment or running the stack.
The `${role_arn}` expression in that example must be defined in ESC or replaced with the role ARN, not left as an unresolved reference.
The environment must export `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` from the login outputs.
These are temporary credentials and must not be copied into repository files.

These authentication resources are already declared in [provider.ts](./aws/src/provider.ts).
After configuring ESC authentication, import the manually registered OIDC provider and role into the `aws/production` Pulumi stack before the first update instead of creating duplicate resources.
Use Pulumi logical names `iac-prod-pulumi-oidc` and `iac-prod-pulumi`, respectively, for new production imports.
Use the OIDC provider ARN as its import ID and the IAM role's name, not its ARN, as the role's import ID.
If the resources are already tracked by the stack, reuse them and do not import them again.
Review the preview before applying because Pulumi will reconcile manually configured trust and permissions with the source code.

Reference: [Pulumi ESC AWS OIDC setup](https://www.pulumi.com/docs/esc/guides/configuring-oidc/aws/) and [AWS login provider](https://www.pulumi.com/docs/esc/providers/login/aws-login/).

### Cloudflare: API Token Permissions

Use a custom Cloudflare **API Token**, not a Global API Key, because this stack consumes `cloudflare:apiToken`.
Limit its account resources to the account identified by `CLOUDFLARE_ACCOUNT_ID`.
The current stack's management token needs the following account permissions:

| Account permission                                      | Level  | Managed resources                                |
| ------------------------------------------------------- | ------ | ------------------------------------------------ |
| `Access: Organizations, Identity Providers, and Groups` | `Edit` | Access groups and the AWS SAML identity provider |
| `Access: Apps and Policies`                             | `Edit` | Reusable Access policies                         |
| `AI Gateway`                                            | `Edit` | The authenticated AI Gateway                     |

The API and Pulumi SDK call these write permissions `Write`, while the token dashboard labels them `Edit`.
The corresponding `Read` permissions alone do not authorize deployment changes.
The current stack does not require DNS, zone, or Workers permissions.
An `AI Gateway Run` token is for inference clients, not infrastructure management, and should be separate from this deployment token.
AI Gateway token permissions are account-wide and cannot be restricted to one gateway.

Register the management token as an ESC secret in `cloudflare/production` using the [Cloudflare configuration example](./cloudflare/README.md), which shows the dummy plaintext form before registration.
Replace the dummy only in ESC, not in the repository.
The environment must set `values.pulumiConfig["cloudflare:apiToken"]` and export `CLOUDFLARE_ACCOUNT_ID` for [config.ts](./cloudflare/src/config.ts).

Reference: [Cloudflare API token permissions](https://developers.cloudflare.com/fundamentals/api/reference/permissions/) and [AI Gateway authentication](https://developers.cloudflare.com/ai-gateway/configuration/authentication/).

## Development Checks

Run formatting, linting, and type checking with the shared Vite+ configuration from the repository root:

```bash
vp check --fix infra
vp check infra
```

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

- Zero Trust Access groups
- Access policies
- Identity providers (including AWS SAML)
- An authenticated AI Gateway

## Configuration Management

### Pulumi ESC

Both projects use Pulumi ESC for secrets and configuration management:

- **AWS**: OIDC authentication via IAM roles
- **Cloudflare**: API token stored in Pulumi ESC

Configuration is defined in:

- `aws/production` environment (for AWS)
- `cloudflare/production` environment (for Cloudflare)

### Cross-Project Configuration

The current Cloudflare program does not declare an AWS `StackReference`.
AWS SAML metadata is configured explicitly in [identity-provider.ts](./cloudflare/src/identity-provider.ts), so complete the manual SAML configuration step above after deploying AWS.
