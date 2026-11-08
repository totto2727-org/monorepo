# GitHub Infrastructure

## Prerequisites

- Pulumi CLI: `brew install pulumi` → `pulumi login`.
- Pulumi organization `totto2727`: production stack and ESC environment.
- GitHub: access to the managed `totto2727-org` repositories.
- Commands: run from the repository root.

## 1. GitHub Token Permissions

Create a fine-grained personal access token for the managed repositories in `totto2727-org`:

| Repository permission | Level          |
| --------------------- | -------------- |
| Administration        | Read and write |
| Contents              | Read and write |
| Metadata              | Read           |

## 2. Pulumi ESC

### github/production

Pulumi Console → **ESC → `github/production`**: replace `dummy-github-token` with the created token.

```yaml
values:
  github:
    token:
      fn::secret: dummy-github-token
  environmentVariables:
    GITHUB_TOKEN: ${github.token}
```

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

- [Repository definitions](./src/repository.ts)
- [Pulumi GitHub provider authentication](https://www.pulumi.com/registry/packages/github/installation-configuration/)
