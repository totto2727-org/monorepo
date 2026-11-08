import * as pulumi from '@pulumi/pulumi'
import { beforeAll, describe, expect, test } from 'vite-plus/test'

import { defaultBranchRules, repositoryOptions, repositorySettings } from './policy.ts'

const repositoryType = 'github:index/repository:Repository'
const rulesetType = 'github:index/repositoryRuleset:RepositoryRuleset'
const resources: pulumi.runtime.MockResourceArgs[] = []
const expectedNames = [
  'workspace',
  'agent',
  'monorepo',
  'agent-core-sdk',
  'agent-sdk',
  'codex-sdk',
  'opencode-sdk',
  'atlas-to-kysely',
  'c-plugin',
  'cloudflare-os-starter',
  'flowdeck',
  'glossshift',
  'mdts',
  'open-connector',
  'projektor',
  'reylo',
  'admiral',
  'llm-profiles',
  'any-collection',
  'oxlint',
  'oxlint-docs',
  'effront',
  'e2e',
  'geo',
  'gitignore-patterns',
  'lens',
  'workgraph',
  'x',
  'template-go-simple',
  'template-vite-plus-lib',
  'template-vite-plus-app',
  'template-moonbit-simple',
  'template-rust-simple',
  'template-haskell-simple',
  'moonbit-overlay',
]
const checkExceptions: Record<string, string[]> = {
  'cloudflare-os-starter': [],
  geo: ['test'],
  mdts: [],
  'moonbit-overlay': ['flake-check'],
  'open-connector': ['Lint, Typecheck & Test'],
  projektor: ['Test & type-check'],
  reylo: ['SQLite and HCL on ubuntu-latest', 'SQLite and HCL on windows-latest'],
  workspace: [],
  x: ['verify'],
}
let resolvedNames: string[] = []
let resolvedRulesetIds: string[] = []

beforeAll(async () => {
  await pulumi.runtime.setMocks(
    {
      call: (args) => {
        throw new Error(`Unexpected provider invocation: ${args.token}`)
      },
      newResource: (args) => {
        resources.push(args)
        // oxlint-disable-next-line typescript/no-unsafe-assignment -- Pulumi mock inputs are any and must be echoed as resource state.
        return { id: `id-${args.name}`, state: args.inputs }
      },
    },
    'github',
    'production',
  )
  const stack = await import('../index.ts')
  const { promise, resolve } = Promise.withResolvers<boolean>()
  pulumi.all([pulumi.all(stack.repositoryNames), pulumi.all(stack.rulesetIds)]).apply(([names, ids]) => {
    resolvedNames = names
    resolvedRulesetIds = ids
    resolve(true)
  })
  await promise
})

describe('Existing workspace repository management', () => {
  test('manages exactly the 35 organization repositories and no organization resources', () => {
    expect(resolvedNames.toSorted()).toEqual(expectedNames.toSorted())
    expect(new Set(resolvedNames).size).toBe(35)
    expect(resolvedRulesetIds).toHaveLength(35)
    expect(new Set(resolvedRulesetIds).size).toBe(35)
    expect(resources.filter((resource) => resource.type === repositoryType)).toHaveLength(35)
    expect(resources.filter((resource) => resource.type === rulesetType)).toHaveLength(35)
    expect(resources.filter((resource) => resource.type === 'pulumi:providers:github')).toHaveLength(1)
    expect(
      resources.every((resource) => [repositoryType, rulesetType, 'pulumi:providers:github'].includes(resource.type)),
    ).toBe(true)
  })

  test('manages the intended repository merge settings and explicit existing attributes', () => {
    expect(repositorySettings).toMatchObject({
      allowAutoMerge: true,
      allowMergeCommit: true,
      allowRebaseMerge: false,
      allowSquashMerge: false,
      allowUpdateBranch: true,
      deleteBranchOnMerge: true,
      mergeCommitMessage: 'PR_TITLE',
      mergeCommitTitle: 'MERGE_MESSAGE',
      webCommitSignoffRequired: true,
    })
    for (const name of expectedNames) {
      expect(resources.find((resource) => resource.name === `repository-${name}`)?.inputs).toMatchObject({
        allowAutoMerge: true,
        allowForking: true,
        allowMergeCommit: true,
        allowRebaseMerge: false,
        allowSquashMerge: false,
        allowUpdateBranch: true,
        archived: false,
        deleteBranchOnMerge: true,
        hasDiscussions: false,
        mergeCommitMessage: 'PR_TITLE',
        mergeCommitTitle: 'MERGE_MESSAGE',
        name,
        visibility: 'public',
        webCommitSignoffRequired: true,
      })
    }
    expect(resources.find((resource) => resource.name === 'repository-monorepo')?.inputs).toMatchObject({
      hasProjects: false,
      hasWiki: false,
      securityAndAnalysis: {
        secretScanning: { status: 'enabled' },
        secretScanningPushProtection: { status: 'enabled' },
      },
    })
    for (const name of expectedNames) {
      expect(resources.find((resource) => resource.name === `repository-${name}`)?.inputs).toMatchObject({
        isTemplate: name.startsWith('template-'),
      })
    }
  })

  test('adopts exact existing names without ignoring configuration drift', () => {
    for (const name of expectedNames) {
      expect(resources.find((resource) => resource.name === `repository-${name}`)?.id).toBe(name)
      expect(repositoryOptions(name)).toEqual({
        import: name,
        protect: true,
        retainOnDelete: true,
      })
    }
  })

  test('adds symbolic default-branch protection without taking ownership of existing queues', () => {
    for (const name of expectedNames) {
      const checks = checkExceptions[name] ?? ['check']
      expect(resources.find((resource) => resource.name === `default-branch-${name}`)?.inputs).toEqual({
        bypassActors: [
          { actorType: 'OrganizationAdmin', bypassMode: 'always' },
          { actorId: 5, actorType: 'RepositoryRole', bypassMode: 'always' },
        ],
        conditions: { refName: { excludes: [], includes: ['~DEFAULT_BRANCH'] } },
        enforcement: 'active',
        name: 'Workspace default branch',
        repository: name,
        rules: defaultBranchRules(checks),
        target: 'branch',
      })
      expect(defaultBranchRules(checks)).not.toHaveProperty('mergeQueue')
      expect(defaultBranchRules(checks)).toMatchObject({
        deletion: true,
        nonFastForward: true,
        pullRequest: { allowedMergeMethods: ['merge'], requiredApprovingReviewCount: 0 },
      })
    }
  })

  test('requires exact per-repository CI and omits checks for the three repositories without CI', () => {
    for (const name of expectedNames) {
      const checks = checkExceptions[name] ?? ['check']
      if (['workspace', 'mdts', 'cloudflare-os-starter'].includes(name)) {
        expect(defaultBranchRules(checks)).not.toHaveProperty('requiredStatusChecks')
      } else {
        expect(defaultBranchRules(checks).requiredStatusChecks).toEqual({
          doNotEnforceOnCreate: false,
          requiredChecks: checks.map((context) => ({ context, integrationId: 15_368 })),
          strictRequiredStatusChecksPolicy: false,
        })
      }
    }
  })

  test('binds every repository and ruleset to the fixed organization provider', () => {
    expect(resources.find((resource) => resource.type === 'pulumi:providers:github')?.inputs).toMatchObject({
      owner: 'totto2727-org',
    })
    for (const resource of resources.filter((entry) => [repositoryType, rulesetType].includes(entry.type))) {
      expect(resource.provider).toContain('pulumi:providers:github::github::id-github')
    }
  })
})
