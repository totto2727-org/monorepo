# Cloudflare Infrastructure

## Prerequisites

- Cloudflare: API token creation for account `5643a837ef66765e7881c0831a36ebed`.
- Commands: run from the repository root.
- Native passkey support: `@pulumi/cloudflare` 6.23.3 or later.

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

## 3. Passkey Access Configuration

The stack creates the native `passkeys` identity provider in [`src/identity-provider.ts`](./src/identity-provider.ts).
It does not require an external identity provider or AWS IAM Identity Center.
Automatic browser prompts are disabled so enrollment and recovery controls remain visible on the login page.
With passkeys as the only login method, Access verifies enrollment with an email code.

Manage allowed email addresses in [`src/access-group.ts`](./src/access-group.ts).
The group requires both an allowed email and authentication with the passkey provider.
Keep email rules in `includes` and the login-method rule in `requires`, so registering a passkey alone does not grant access.
This policy limits application access, not who can register a passkey.

Protect the allowed mailboxes and keep a recovery passkey available.
To remove access, update the email allowlist and revoke active Access sessions.
Deleting a passkey alone does not end existing sessions.

## 4. Deploy

```bash
pulumi preview --cwd infra/cloudflare --stack production
pulumi up --cwd infra/cloudflare --stack production
```

Preview and mock tests do not verify browser enrollment or application authorization.
Verify sign-in and denial behavior with fresh browser sessions when changing authentication policies.

## Checks

```bash
vp check infra/cloudflare infra/aws
vp test run --dir infra
```

## References

- [Cloudflare token permissions](https://developers.cloudflare.com/fundamentals/api/reference/permissions/)
- [Native Access passkeys and enrollment](https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/passkeys/)
- [Access rule groups](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/groups/)
