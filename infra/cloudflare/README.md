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

## 4. Access Authentication

The applications support the native `passkeys` identity provider and AWS SAML.
Their login pages allow users to choose a method instead of redirecting directly to SAML.
Native passkey support requires `@pulumi/cloudflare` 6.23.3 or later.
Automatic browser prompts are disabled so login-method selection remains visible.

Manage allowed passkey users in [`src/access-group.ts`](./src/access-group.ts).
Keep email rules in `includes` and the login-method rule in `requires`, so access requires both an allowed email and authentication with the passkey provider.
This policy limits application access, not who can register a passkey.

Protect the allowed mailboxes and keep a recovery passkey available.
To remove access, update the email allowlist and revoke active Access sessions.
Deleting a passkey alone does not end existing sessions.

## 5. Deploy

```bash
pulumi preview --cwd infra/cloudflare --stack production
pulumi up --cwd infra/cloudflare --stack production
```

Preview and mock tests do not verify browser enrollment or application authorization.
Verify sign-in and denial behavior with fresh browser sessions when changing authentication policies.

## Checks

```bash
vp check infra/cloudflare
vp test run --dir infra/cloudflare
```

## References

- [Cloudflare token permissions](https://developers.cloudflare.com/fundamentals/api/reference/permissions/)
- [Native Access passkeys and enrollment](https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/passkeys/)
- [Access rule groups](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/groups/)
