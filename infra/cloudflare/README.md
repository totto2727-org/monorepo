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

### Passkey rollout

The stack adds a native `passkeys` identity provider alongside AWS SAML.
Both application login pages offer a choice instead of redirecting directly to SAML.
The passkey rule group permits only the two email addresses currently assigned to the AWS Cloudflare Access application and requires authentication with the passkey provider.
Keep email rules in `includes` and the login-method rule in `requires`, so a registered passkey alone does not grant access.
AWS SAML configuration and assignments are retained during this rollout.

1. Run `pulumi preview --cwd infra/cloudflare --stack production` and confirm that no resources are deleted or replaced.
2. Deploy this introduction change.
3. Open both `https://projektor.totto2727.dev` and `https://cloudflare.totto2727.dev` in a fresh browser session.
4. Select **Sign in with a passkey**, then **Don't have a passkey? Set one up**, and verify the identity with the existing login method.
5. Register a passkey and confirm a new passkey sign-in works for each allowed user on both applications.
6. Confirm an unlisted email cannot access either application and AWS SAML still works as the fallback.
7. If the App Launcher or other applications use the old SAML provider, migrate and test them separately before retiring SAML.
8. Merge and deploy the separate SAML-removal change only after these checks pass.

The stack requires `@pulumi/cloudflare` 6.23.3 or later for native `passkeys` support.
It sets `loginPageAutoPrompt` to `false` so users can choose between passkeys and the SAML fallback.
Preview and mock tests do not prove that the Cloudflare API accepts this newly introduced provider type or that browser enrollment works.
If the API rejects it, stop the rollout and keep SAML until the provider supports it.
If a Passkeys provider already exists in the account, import it as `iac-prod-passkeys-identity-provider` before deploying instead of creating a duplicate.

In the final passkey-only configuration, Access verifies new enrollments with an email code.
Protect the allowed mailboxes and keep a recovery passkey available.
To remove access, update the email allowlist and revoke active Access sessions.
Deleting a passkey alone does not end existing sessions.

```bash
pulumi up --cwd infra/cloudflare --stack production
```

## Checks

```bash
vp check infra/cloudflare
vp test run --dir infra/cloudflare
```

## References

- [Cloudflare token permissions](https://developers.cloudflare.com/fundamentals/api/reference/permissions/)
- [Native Access passkeys and enrollment](https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/passkeys/)
- [Access rule groups](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/groups/)
