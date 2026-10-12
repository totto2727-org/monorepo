# Deploy with Alchemy

Deploy an Alchemy stack and return its `url` output as a URL origin.
The caller owns checkout, Nix setup, dependency installation, builds, stage selection, credentials, permissions, and concurrency.
The action uses the caller's root Nix `default` development shell and the installed Alchemy CLI.
The stack must return `{ url: ... }`, and `state-backend` must match its state configuration.

```yaml
- name: Deploy documentation
  id: deploy
  uses: totto2727-org/monorepo/.github/actions/deploy-alchemy@main
  with:
    working-directory: app/docs
    stack-name: effront-docs
    stage: ${{ steps.stage.outputs.name }}
  env:
    CLOUDFLARE_ACCOUNT_ID: ${{ vars.CLOUDFLARE_ACCOUNT_ID }}
    CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

`working-directory`, `stack-name`, and `stage` are required.
`state-backend` defaults to `cloudflare`.
Use `steps.deploy.outputs.url` for a GitHub Environment URL or a later step.
The action also adds the deployment link to the job summary.
It does not select production or Preview mode, change the stack's backend, or manage cleanup.
