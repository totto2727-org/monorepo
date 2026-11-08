# Cloudflare Infrastructure

> [!WARNING]
> For an existing SAML installation, complete the [migration and approval checks](#retire-legacy-aws-saml) before applying this removal.

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
If a Passkeys provider already exists in the account, import it as `iac-prod-passkeys-identity-provider` before deploying instead of creating a duplicate.

Manage allowed email addresses in [`src/access-group.ts`](./src/access-group.ts).
The group requires both an allowed email and authentication with the passkey provider.
Keep email rules in `includes` and the login-method rule in `requires`, so registering a passkey alone does not grant access.
The allowlist retains the two users previously assigned to the AWS Cloudflare Access application.

## 4. Deploy

```bash
pulumi preview --cwd infra/cloudflare --stack production
pulumi up --cwd infra/cloudflare --stack production
```

Preview and mock tests do not prove that browser enrollment works.
After deployment, open both `https://projektor.totto2727.dev` and `https://cloudflare.totto2727.dev` in fresh browser sessions.
Select **Sign in with a passkey**, then **Don't have a passkey? Set one up**.
With passkeys as the only login method, Access verifies enrollment with an email code.
Confirm each allowed user can enroll and sign in to both applications, and an unlisted email cannot access either application.

Protect the allowed mailboxes and keep a recovery passkey available.
To remove access, update the email allowlist and revoke active Access sessions.
Deleting a passkey alone does not end existing sessions.

### Retire legacy AWS SAML

This procedure applies only to existing installations with the old SAML resources in Pulumi state.
Do not deploy this removal until the [Passkey introduction change](https://github.com/totto2727-org/monorepo/pull/395) is merged and deployed, both users can sign in with passkeys on both applications in fresh browser sessions, and unlisted users are denied.
Migrate the App Launcher and any other applications that still use the old SAML provider before removing it.
Confirm that AWS administrator sign-in and a recovery path remain available.

The legacy resources are protected in state.
A removal preview must stop while they remain protected.
After migration verification and explicit approval, inspect their actual URNs with `pulumi stack --cwd infra/cloudflare --stack production --show-urns` and the corresponding AWS command.
Unprotect only the named resources below, never the entire stack.
If the actual URNs differ, stop and confirm their identities before continuing.

First retire the Cloudflare SAML resources:

```bash
pulumi state unprotect --cwd infra/cloudflare --stack production \
  'urn:pulumi:production::cloudflare::cloudflare:index/zeroTrustAccessPolicy:ZeroTrustAccessPolicy::iac-prod-must-authenticate-with-saml' \
  'urn:pulumi:production::cloudflare::cloudflare:index/zeroTrustAccessGroup:ZeroTrustAccessGroup::iac-prod-saml-access-group' \
  'urn:pulumi:production::cloudflare::cloudflare:index/zeroTrustAccessIdentityProvider:ZeroTrustAccessIdentityProvider::iac-prod-aws-saml-identity-provider'
pulumi preview --cwd infra/cloudflare --stack production
pulumi up --cwd infra/cloudflare --stack production
```

Before applying, confirm the preview deletes only these three legacy resources and does not replace the passkey provider or either Access application.
After applying, verify fresh passkey sign-ins again before retiring the AWS integration:

```bash
pulumi state unprotect --cwd infra/aws --stack production \
  'urn:pulumi:production::aws::aws:ssoadmin/applicationAssignment:ApplicationAssignment::iac-prod-cloudflare-application-assignment' \
  'urn:pulumi:production::aws::aws:ssoadmin/application:Application::iac-prod-cloudflare-access-application' \
  'urn:pulumi:production::aws::aws:identitystore/groupMembership:GroupMembership::iac-prod-cloudflare-access-totto2727' \
  'urn:pulumi:production::aws::aws:identitystore/groupMembership:GroupMembership::iac-prod-cloudflare-access-test' \
  'urn:pulumi:production::aws::aws:identitystore/group:Group::iac-prod-cloudflare-access'
pulumi preview --cwd infra/aws --stack production
pulumi up --cwd infra/aws --stack production
```

Before applying, confirm the AWS preview deletes only these five resources.
The AWS users, administrator group and membership, account permission assignments, and Pulumi OIDC role must remain intact.
This repository change does not unprotect resources or apply either stack automatically.

## Checks

```bash
vp check infra/cloudflare infra/aws
vp test run --dir infra
```

## References

- [Cloudflare token permissions](https://developers.cloudflare.com/fundamentals/api/reference/permissions/)
- [Native Access passkeys and enrollment](https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/passkeys/)
- [Access rule groups](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/groups/)
