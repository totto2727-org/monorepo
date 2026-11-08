# GitHub repository management

This Pulumi project manages existing `totto2727-org` repositories represented in the virtual workspace.
It does not manage the organization, members, teams, installations, secrets, Actions permissions, webhooks, or upstream repositories.
It does not create repositories.

## Scope and ownership

[`repositories.json`](./repositories.json) is the explicit inventory for both the program and the import manifest.
It contains 35 repositories, including the workspace repository itself.
Repositories outside this list are not discovered or adopted automatically.
The local `nix-cache` prototype has no remote, and `projektor-deploy-example` belongs to `TAJD`, so neither is included.
Nested dependency clones and temporary worktrees are not separate managed repositories.

The common policy follows the live `monorepo` repository settings and its active `Default` ruleset, inspected on 2026-11-08.
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
At inspection time, all 35 repositories were public and unarchived, seven were forks, and six were templates.
These observations are not desired-state declarations.
In particular, `moonbit-overlay` keeps its `master` default branch.

### Default-branch rules

Each repository receives one additional ruleset named `Workspace default branch`:

- Apply to `~DEFAULT_BRANCH`, not a hard-coded `main` branch.
- Block deletion and non-fast-forward updates.
- Require a pull request and allow merge commits only.
- Require zero approving reviews, matching the existing `monorepo` baseline.
- Do not add code-owner review, stale-review dismissal, last-push approval, conversation-resolution, or strict up-to-date requirements.
- Require the repository-specific GitHub Actions checks listed below.
- Allow organization owners and repository administrators to bypass rules, matching the existing `monorepo` emergency-administration policy.

Existing rulesets and classic branch protections remain untouched and continue to apply alongside the new ruleset.
A stricter existing rule still applies.
In particular, the existing `monorepo` `Default` ruleset retains its merge queue and its extra-approval requirement for unattributed changes.
The selected provider does not expose that extra-approval setting, so this project does not adopt or rewrite that ruleset.
The disabled Copilot ruleset also remains untouched.

No new merge queues are enabled by this project.
Only `agent` and `monorepo` had `merge_group` CI triggers at inspection time, and the existing `monorepo` queue is retained rather than duplicated.
Before enabling a queue elsewhere, confirm plan support and successful execution of every required check on `merge_group`.
A trigger alone is not evidence that the complete queue workflow works.

### Required checks

The list uses CI job display names, including expanded matrix names, rather than assuming every repository produces `check`.
Check names are bound to the GitHub Actions application, ID `15368`, verified through `GET /apps/github-actions`.
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

## Authentication and stack setup

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

Before deployment, make suitable GitHub provider credentials available securely through the deployment environment, for example a Pulumi ESC environment that exports `GITHUB_TOKEN`.
No credential or new ESC environment is committed here.
The provider needs access to all inventory repositories and permission to administer repository settings and rulesets.
For GitHub App authentication, the provider also documents a `contents:write` permission requirement to read merge settings correctly.
Insufficient permission can produce misleading diffs, not just an authentication error.
Stop if owner, access, or permission checks fail.
Do not substitute a different identity to work around the failure.

If the `github` production stack does not exist yet, an operator must initialize it in the intended Pulumi organization and configure its authentication before adoption.
Stack initialization and applying this program are separate deployment operations, not part of opening this code change.

## Adopt existing repositories before applying policy

Adoption records existing repository IDs in Pulumi state without creating or changing GitHub repositories.
The program's `import` option is a second guard against accidental creation when state is missing.
An inline import can reject a mismatch with the desired merge policy, so bulk import the current repository state first.
Do not remove the `import` guard to make a mismatched import proceed.

1. Confirm that all inventory names still exist under `totto2727-org`, and compare live default-branch CI with the required-check list.
2. Check existing protections, pending pull requests, active merge queues, Actions availability, and the effect of merge-only policy on every repository.
3. Confirm that no repository already has an unrelated ruleset named `Workspace default branch`.
4. Select the intended production stack and securely back up any existing state before importing.
5. Generate the manifest from the same inventory that the program uses:

   ```bash
   mkdir -p tmp
   just github-import-manifest > tmp/github-imports.json
   jq '.resources | length' tmp/github-imports.json # Must be 35.
   ```

6. Import only repositories missing from state.
   For a new, empty stack, the full manifest is appropriate:

   ```bash
   pulumi -C infra/github import --stack totto2727/production \
     --file ../../tmp/github-imports.json --generate-code=false
   ```

   For a partially adopted stack, generate a temporary filtered manifest containing only missing logical names after inspecting state.
   Do not reimport existing URNs or forget the provider's configured owner.
   The import IDs are repository names, and logical names are `repository-<name>`.
   This operation changes Pulumi state only and must not include repository creation or a GitHub update.

7. Preview with refreshed state:

   ```bash
   pulumi -C infra/github preview --stack totto2727/production --refresh --diff
   ```

   Expect at most 35 new `Workspace default branch` rulesets and updates limited to the owned merge settings above.
   Existing `monorepo` merge settings should need no GitHub change.
   Require zero repository creates, deletes, replacements, or renames.
   Require zero changes to visibility, templates, fork sources, features, default branches, security settings, existing rulesets, and classic branch protection.
   Stop on any unexpected difference or unavailable required check.

8. After explicit deployment approval, apply the reviewed plan in the same stack and identity.
   Verify a representative pull request in each CI category, branch cleanup after merge, both `reylo` matrix checks, and the existing `monorepo` merge queue.
   A policy preview does not prove that live CI, branch cleanup, or the merge queue works.

Repository and managed ruleset resources have both `protect: true` and `retainOnDelete: true`.
Protection blocks accidental deletion or replacement, and retention preserves the remote object if it is deliberately removed from state later.
Neither option substitutes for importing existing repositories or reviewing the preview.
Retiring an inventory entry requires a separate reviewed state transition, not deletion of the GitHub repository or its existing protections.

## Validation

```bash
vp check infra/github infra/README.md infra/AGENTS.md
vp run --filter @infra/github test
just github-import-manifest | jq -e '.resources | length == 35'
```

The tests run the actual Pulumi entry point with provider mocks.
They check the complete inventory, common settings, owner guard, adoption options, per-repository CI checks, default-branch selection, and absence of organization resources.
Mock tests do not verify GitHub permissions, provider import behavior against live state, or successful merges.
The import and live preview gates above remain required before deployment.

## References

- [Monorepo baseline settings](https://github.com/totto2727-org/monorepo/settings)
- [Pulumi GitHub Repository and import IDs](https://www.pulumi.com/registry/packages/github/api-docs/repository/)
- [Pulumi GitHub RepositoryRuleset](https://www.pulumi.com/registry/packages/github/api-docs/repositoryruleset/)
- [Pulumi GitHub provider authentication](https://www.pulumi.com/registry/packages/github/installation-configuration/)
- [GitHub ruleset composition](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
- [GitHub merge queue workflow requirements](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue)
