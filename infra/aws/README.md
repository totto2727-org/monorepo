# AWS Infrastructure

AWS Infrastructure as Code (IaC) implementation using Pulumi.

## Setup

### 1. Configure AWS Credentials

AWS CLI is recommended for authentication setup:

```bash
aws configure
```

### 2. Deploy Pulumi Stack

For initial deployment, disable Pulumi ESC before deploying:

```bash
# Comment out or remove the environments section in Pulumi.production.yaml
pulumi up
```

### 3. Configure Pulumi ESC (Environments, Secrets, and Configuration)

After deployment, configure OIDC authentication in Pulumi ESC.

Add the following configuration to the `aws/production` environment:

```yaml
values:
  aws:
    login:
      fn::open::aws-login:
        oidc:
          duration: 1h
          roleArn: ${role_arn} # Specify the ARN of the role created during deployment
          sessionName: pulumi-environments-session
  environmentVariables:
    AWS_ACCESS_KEY_ID: ${aws.login.accessKeyId}
    AWS_SECRET_ACCESS_KEY: ${aws.login.secretAccessKey}
    AWS_SESSION_TOKEN: ${aws.login.sessionToken}
```

## Resource Architecture

This project manages the following AWS resources:

- **IAM Identity Center**: User, group, and permission set management
- **SAML/OIDC Providers**: External IdP integration
- **Organization Settings**: Password policies and security configurations
- **Application Integration**: External service integration (e.g., Cloudflare Access)
