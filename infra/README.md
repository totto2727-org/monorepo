# Infrastructure Deployment

## Required Access

- Pulumi CLI: `brew install pulumi`, then `pulumi login`.
- Pulumi organization `totto2727`: stacks and ESC environments.
- AWS: IAM OIDC provider and role management in the deployment account.
- AWS IAM Identity Center: enabled in `ap-northeast-1`.
- Cloudflare: API token creation for the deployment account.

## 1. AWS Authentication Setup

Replace `<AWS_ACCOUNT_ID>` with the deployment account's 12-digit ID.

### 1.1. Register IAM Resources

AWS Console → **IAM → Identity providers → Add provider**:

| Field    | Value                         |
| -------- | ----------------------------- |
| Type     | OpenID Connect                |
| URL      | `https://api.pulumi.com/oidc` |
| Audience | `aws:totto2727`               |

Provider → **Endpoint verification → Thumbprints → Manage**: `06b25927c42a721631c1efd9431e648fa62e1e39`.

AWS Console → **IAM → Roles → Create role → Custom trust policy**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/api.pulumi.com/oidc"
      },
      "Condition": {
        "StringEquals": {
          "api.pulumi.com/oidc:aud": "aws:totto2727"
        }
      }
    }
  ]
}
```

Role name: **`iac-prod-pulumi`**.

**Permissions policies**: select these AWS managed policies:

- `AWSOrganizationsFullAccess`
- `AWSSSODirectoryAdministrator`
- `AWSSSOMasterAccountAdministrator`
- `AmazonS3FullAccess`
- `IAMFullAccess`

### 1.2. Save the ESC Environment

Pulumi Console → **ESC → `aws/production`**:

```yaml
values:
  aws:
    login:
      fn::open::aws-login:
        oidc:
          duration: 1h
          roleArn: arn:aws:iam::<AWS_ACCOUNT_ID>:role/iac-prod-pulumi
          sessionName: pulumi-environments-session
  environmentVariables:
    AWS_ACCESS_KEY_ID: ${aws.login.accessKeyId}
    AWS_SECRET_ACCESS_KEY: ${aws.login.secretAccessKey}
    AWS_SESSION_TOKEN: ${aws.login.sessionToken}
```

### 1.3. Import into the Production Stack

Run from the repository root, only for resources not already managed by the stack:

```bash
pulumi import --cwd infra/aws --stack production --generate-code=false \
  aws:iam/openIdConnectProvider:OpenIdConnectProvider iac-prod-pulumi-oidc \
  'arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/api.pulumi.com/oidc'
pulumi import --cwd infra/aws --stack production --generate-code=false \
  aws:iam/role:Role iac-prod-pulumi iac-prod-pulumi
```

## 2. Cloudflare Authentication Setup

1. Cloudflare Console → **My Profile → API Tokens → Create Token → Custom token**.
2. Set **Account Resources → Include → Specific account** to `5643a837ef66765e7881c0831a36ebed`.
3. Add these permissions:

   | Scope   | Permission                                            | Level |
   | ------- | ----------------------------------------------------- | ----- |
   | Account | Access: Organizations, Identity Providers, and Groups | Edit  |
   | Account | Access: Apps and Policies                             | Edit  |
   | Account | AI Gateway                                            | Edit  |

4. Save the [ESC configuration](./cloudflare/README.md#cloudflareproduction) to **`cloudflare/production`**, replacing `dummy-cloudflare-api-token` with the created token.

## 3. Deploy

1. First deployment: AWS Console → **IAM Identity Center → Applications → Add application → SAML 2.0**.

   | Field                | Value                                                                               |
   | -------------------- | ----------------------------------------------------------------------------------- |
   | Display name         | `iac-prod-cloudflare-access`                                                        |
   | Application metadata | Download from `https://totto2727.cloudflareaccess.com/cdn-cgi/access/saml-metadata` |
   | Attribute mappings   | [Existing values](./aws/docs/cloudflare-saml-mapping.png), format `unspecified`     |
   | `<APPLICATION_ARN>`  | Copy the application ARN from Application details                                   |

   Import the application if not already managed by the stack:

   ```bash
   pulumi import --cwd infra/aws --stack production --generate-code=false \
     aws:ssoadmin/application:Application iac-prod-cloudflare-access-application \
     '<APPLICATION_ARN>'
   ```

2. Deploy AWS:

   ```bash
   pulumi up --cwd infra/aws --stack production
   ```

3. AWS Console → **IAM Identity Center → Applications → Application details**: copy the SAML values into [`cloudflare/src/identity-provider.ts`](./cloudflare/src/identity-provider.ts).

   | AWS value        | Configuration key |
   | ---------------- | ----------------- |
   | SAML certificate | `idpPublicCerts`  |
   | SAML issuer      | `issuerUrl`       |
   | SAML sign-in URL | `ssoTargetUrl`    |

4. Deploy Cloudflare:

   ```bash
   pulumi up --cwd infra/cloudflare --stack production
   ```

## Checks

```bash
vp check infra
vp test run --dir infra/cloudflare
```

## References

- [IAM source](./aws/src/provider.ts) · [AWS OIDC provider setup](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html) · [Pulumi ESC AWS setup](https://www.pulumi.com/docs/esc/guides/configuring-oidc/aws/)
- [Cloudflare token permissions](https://developers.cloudflare.com/fundamentals/api/reference/permissions/)
