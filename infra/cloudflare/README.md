# Cloudflare Infrastructure

## Prerequisites

- [AWS setup and deployment](../aws/README.md): completed.
- Cloudflare: API token creation for account `5643a837ef66765e7881c0831a36ebed`.
- Commands: run from the repository root.

## 1. API Token Permissions

Cloudflare Console → **My Profile → API Tokens → Create Token → Custom token**:

| Scope   | Permission                                            | Level |
| ------- | ----------------------------------------------------- | ----- |
| Account | Access: Organizations, Identity Providers, and Groups | Edit  |
| Account | Access: Apps and Policies                             | Edit  |
| Account | AI Gateway                                            | Edit  |

**Account Resources → Include → Specific account**: `5643a837ef66765e7881c0831a36ebed`.

## 2. Pulumi ESC

### cloudflare/production

Pulumi Console → **ESC → `cloudflare/production`**: replace `dummy-cloudflare-api-token` with the created token.

```yaml
values:
  cloudflare:
    CLOUDFLARE_API_TOKEN:
      fn::secret: dummy-cloudflare-api-token
    CLOUDFLARE_ACCOUNT_ID: 5643a837ef66765e7881c0831a36ebed
  environmentVariables:
    CLOUDFLARE_ACCOUNT_ID: ${cloudflare.CLOUDFLARE_ACCOUNT_ID}
  pulumiConfig:
    cloudflare:apiToken: ${cloudflare.CLOUDFLARE_API_TOKEN}
```

## 3. AWS SAML Configuration

AWS Console → **IAM Identity Center → Applications → Application details** → [`src/identity-provider.ts`](./src/identity-provider.ts):

| AWS value        | Configuration key |
| ---------------- | ----------------- |
| SAML certificate | `idpPublicCerts`  |
| SAML issuer      | `issuerUrl`       |
| SAML sign-in URL | `ssoTargetUrl`    |

## 4. Deploy

```bash
pulumi up --cwd infra/cloudflare --stack production
```

## Checks

```bash
vp check infra/cloudflare
vp test run --dir infra/cloudflare
```

## Deployment Access Applications

After deployment, copy each AUD output into the corresponding deployment setting.

| Application   | AUD output                   | Deployment setting                          |
| ------------- | ---------------------------- | ------------------------------------------- |
| Projektor     | `projektorAccessAudience`    | `wrangler.toml` → `vars.CF_ACCESS_AUDIENCE` |
| Cloudflare OS | `cloudflareOsAccessAudience` | `deployment.jsonc` → `access.audience`      |

```bash
pulumi stack output projektorAccessAudience --cwd infra/cloudflare --stack production
pulumi stack output cloudflareOsAccessAudience --cwd infra/cloudflare --stack production
```

## References

- [Cloudflare token permissions](https://developers.cloudflare.com/fundamentals/api/reference/permissions/)
