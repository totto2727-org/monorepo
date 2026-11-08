import * as github from '@pulumi/github'
import * as pulumi from '@pulumi/pulumi'

import definitions from './repositories.json' with { type: 'json' }
import { defaultBranchRules, repositoryOptions, repositorySettings, requireManagedOwner } from './src/policy.ts'

// This validated config also scopes the default provider used by the import manifest.
requireManagedOwner(new pulumi.Config('github').require('owner'))

const managedRepositories = definitions.map((definition) => {
  const repository = new github.Repository(
    `repository-${definition.name}`,
    { ...repositorySettings, name: definition.name },
    repositoryOptions(definition.name),
  )

  const ruleset = new github.RepositoryRuleset(
    `default-branch-${definition.name}`,
    {
      // Existing rulesets and classic branch protection remain outside this stack.
      bypassActors: [
        { actorType: 'OrganizationAdmin', bypassMode: 'always' },
        { actorId: 5, actorType: 'RepositoryRole', bypassMode: 'always' },
      ],
      conditions: { refName: { excludes: [], includes: ['~DEFAULT_BRANCH'] } },
      enforcement: 'active',
      name: 'Workspace default branch',
      repository: repository.name,
      rules: defaultBranchRules(definition.requiredChecks),
      target: 'branch',
    },
    { protect: true, retainOnDelete: true },
  )

  return { repository, ruleset }
})

export const repositoryNames = managedRepositories.map(({ repository }) => repository.name)
export const rulesetIds = managedRepositories.map(({ ruleset }) => ruleset.id)
