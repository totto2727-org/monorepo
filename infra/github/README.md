# GitHub repository management

This Pulumi project manages existing `totto2727-org` repositories represented in the virtual workspace.
It does not manage the organization, members, teams, installations, secrets, Actions permissions, webhooks, or upstream repositories.
It does not create repositories.

## Scope and ownership

[`repositories.json`](./repositories.json) is the explicit inventory for both the program and the import manifest.
Repositories outside this list are not discovered or adopted automatically.
Repositories without an organization-owned remote are outside this project's scope.
Nested dependency clones and temporary worktrees are not separate managed repositories.

The common policy follows the `monorepo` repository settings and its `Default` ruleset.
Only these repository settings are owned by this project:

| Setting                        | Value           |
| ------------------------------ | --------------- |
| Merge commits                  | Enabled         |
| Squash and rebase merges       | Disabled        |
| Automatic merge                | Enabled         |
| Update branch button           | Enabled         |
| Delete head branch after merge | Enabled         |
| Web commit sign-off            | Required        |
| Merge commit title             | `MERGE_MESSAGE` |
| Merge commit message           | `PR_TITLE`      |

Other repository inputs use `ignoreChanges` after import.
Visibility, archived state, template status, fork relationships, default branches, descriptions, topics, repository features, Pages, and security settings remain outside this project's ownership.

### Default-branch rules

Each repository receives one additional ruleset named `Workspace default branch`:

- Apply to `~DEFAULT_BRANCH`, not a hard-coded `main` branch.
- Block deletion and non-fast-forward updates.
- Require a pull request and allow merge commits only.
- Require zero approving reviews, matching the `monorepo` baseline.
- Do not add code-owner review, stale-review dismissal, last-push approval, conversation-resolution, or strict up-to-date requirements.
- Require the repository-specific GitHub Actions checks listed below.
- Allow organization owners and repository administrators to bypass rules, matching the `monorepo` emergency-administration policy.

Existing rulesets and classic branch protections remain untouched and continue to apply alongside the new ruleset.
A stricter existing rule still applies.
In particular, the existing `monorepo` `Default` ruleset retains its merge queue and its extra-approval requirement for unattributed changes.
The selected provider does not expose that extra-approval setting, so this project does not adopt or rewrite that ruleset.

No new merge queues are enabled by this project.
Before enabling a queue, confirm plan support and successful execution of every required check on `merge_group`.
A trigger alone is not evidence that the complete queue workflow works.

### Required checks

The list uses CI job display names, including expanded matrix names, rather than assuming every repository produces `check`.
Check names are bound to the GitHub Actions application, ID `15368`.
Deployment, publication, and manual-only jobs are not merge gates.

| Repositories                                 | Required checks                                                       |
| -------------------------------------------- | --------------------------------------------------------------------- |
| `workspace`, `cloudflare-os-starter`, `mdts` | None: no PR CI workflow                                               |
| `open-connector`                             | `Lint, Typecheck & Test`                                              |
| `projektor`                                  | `Test & type-check`                                                   |
| `reylo`                                      | `SQLite and HCL on ubuntu-latest`, `SQLite and HCL on windows-latest` |
| `geo`                                        | `test`                                                                |
| `x`                                          | `verify`                                                              |
| `moonbit-overlay`                            | `flake-check`                                                         |
| Other inventory entries                      | `check`                                                               |

Review the live default-branch workflow before changing these entries.
Do not require a check that has path filters, is disabled, does not run on pull requests to the default branch, or depends on unavailable fork credentials.
When a workflow renames a check, coordinate the policy update so that no required context is left permanently pending.
The inventory intentionally does not change workflows in forks.

## Authentication and stack configuration

Run commands from the repository root.
Use the installed tools directly, without downloading alternate CLIs.

```bash
vp install --frozen-lockfile
vp run --filter @infra/github test
```

The production stack configuration sets `github:owner` to `totto2727-org`.
The program rejects any other configured owner before registering resources.
The default GitHub provider uses the same configuration for normal updates and CLI imports.
Do not override its owner or import into a different owner's state.

Make suitable GitHub provider credentials available securely through the deployment environment, for example a Pulumi ESC environment that exports `GITHUB_TOKEN`.
No credential or new ESC environment is committed here.
The provider needs access to all inventory repositories and permission to administer repository settings and rulesets.
For GitHub App authentication, the provider also documents a `contents:write` permission requirement to read merge settings correctly.
Insufficient permission can produce misleading diffs, not just an authentication error.
Stop if owner, access, or permission checks fail.
Do not substitute a different identity to work around the failure.

Commands require an existing stack in the intended Pulumi organization with suitable authentication.

## State ownership and import manifest

Existing repository IDs must be recorded in the selected stack's state before policy updates.
Securely back up existing state before changing resource ownership.
The program's `import` option guards against accidental creation when state is missing.
Do not remove that guard to work around an import mismatch.
An import records an existing repository in Pulumi state without creating or changing the GitHub repository.

`just github-import-manifest` writes a Pulumi import manifest to standard output from the same inventory that the program uses.
Import IDs are repository names, and logical names are `repository-<name>`.
Use only missing logical names when importing into a partially managed stack.
Do not reimport existing URNs or change the provider's configured owner.
Do not adopt an unrelated ruleset with the managed name `Workspace default branch`.

Repository and managed ruleset resources have both `protect: true` and `retainOnDelete: true`.
Protection blocks accidental deletion or replacement, and retention preserves the remote object if it is deliberately removed from state later.
Neither option substitutes for importing existing repositories or reviewing the preview.
Retiring an inventory entry requires a separate reviewed state transition, not deletion of the GitHub repository or its existing protections.

## Preview and update boundaries

Review refreshed state before applying changes:

```bash
pulumi -C infra/github preview --stack totto2727/production --refresh --diff
```

Allow only managed ruleset changes and updates to the owned merge settings above.
Require zero repository creates, deletes, replacements, or renames.
Require zero changes to visibility, templates, fork sources, features, default branches, security settings, existing unmanaged rulesets, and classic branch protection.
Stop on any unexpected difference or unavailable required check.
Apply only an explicitly approved plan in the same stack and identity.
A policy preview does not prove that live CI, branch cleanup, or the merge queue works.

## Validation

```bash
vp check infra/github infra/README.md infra/AGENTS.md
vp run --filter @infra/github test
just github-import-manifest | jq '.resources | length'
```

The tests run the actual Pulumi entry point with provider mocks.
They check the complete inventory, common settings, owner guard, adoption options, per-repository CI checks, default-branch selection, and absence of organization resources.
Mock tests do not verify GitHub permissions, provider import behavior against live state, or successful merges.

## References

- [Monorepo baseline settings](https://github.com/totto2727-org/monorepo/settings)
- [Pulumi GitHub Repository and import IDs](https://www.pulumi.com/registry/packages/github/api-docs/repository/)
- [Pulumi GitHub RepositoryRuleset](https://www.pulumi.com/registry/packages/github/api-docs/repositoryruleset/)
- [Pulumi GitHub provider authentication](https://www.pulumi.com/registry/packages/github/installation-configuration/)
- [GitHub ruleset composition](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
- [GitHub merge queue workflow requirements](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue)
