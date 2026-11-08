# GitHub Infrastructure

## Prerequisites

- Pulumi CLI: `brew install pulumi` → `pulumi login`.
- Pulumi organization `totto2727`: production stack and ESC environment.
- GitHub: administrator access to the managed repositories.
- Commands: run from the repository root.

## 1. GitHub App

Register a GitHub App in `totto2727-org` with these repository permissions:

| Repository permission | Level          |
| --------------------- | -------------- |
| Administration        | Read and write |
| Contents              | Read and write |
| Metadata              | Read           |

Disable webhooks and select **Any account** to support installation in additional owners.
Install the App in `totto2727-org`, grant access to the managed repositories, and generate a private key.
Record the App ID, not the Client ID.

## 2. Pulumi ESC

### github/production

Pulumi Console → **ESC → `github/production`**: replace the App ID and private key.

```yaml
values:
  githubApp:
    appId: 123456
    privateKey:
      fn::secret: |
        -----BEGIN RSA PRIVATE KEY-----
        REPLACE_WITH_PRIVATE_KEY
        -----END RSA PRIVATE KEY-----
  tokens:
    totto2727Org:
      fn::open::gh-login:
        appId: ${githubApp.appId}
        privateKey: ${githubApp.privateKey}
        owner: totto2727-org
        permissions:
          administration: write
          contents: write
          metadata: read
  pulumiConfig:
    github:totto2727OrgToken: ${tokens.totto2727Org.accessToken}
```

For another owner, install the same App there and add a separate `gh-login` value and Pulumi token configuration.
Keep private keys in ESC and rotate them when needed.

## 3. Deploy

```bash
pulumi up --cwd infra/github --stack production
```

## Checks

```bash
vp check infra/github
vp test run --dir infra/github
```

## References

- [Repository definitions](./src/totto2727-org.ts)
- [Pulumi ESC gh-login](https://www.pulumi.com/docs/esc/providers/login/gh-login/)
