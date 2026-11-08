import type * as github from '@pulumi/github'
import type * as pulumi from '@pulumi/pulumi'
import { Array } from 'effect'

export const owner = 'totto2727-org'

export const requireManagedOwner = (configuredOwner: string) => {
  if (configuredOwner !== owner) {
    throw new Error(`This project only manages ${owner}, not ${configuredOwner}`)
  }
}

// These inputs remain owned by existing repository administrators, not this stack.
const preservedRepositoryInputs = [
  'allowForking',
  'archiveOnDestroy',
  'archived',
  'autoInit',
  'defaultBranch',
  'description',
  'fork',
  'gitignoreTemplate',
  'hasDiscussions',
  'hasDownloads',
  'hasIssues',
  'hasProjects',
  'hasWiki',
  'homepageUrl',
  'ignoreVulnerabilityAlertsDuringRead',
  'isTemplate',
  'licenseTemplate',
  'pages',
  'private',
  'securityAndAnalysis',
  'sourceOwner',
  'sourceRepo',
  'squashMergeCommitMessage',
  'squashMergeCommitTitle',
  'template',
  'topics',
  'visibility',
  'vulnerabilityAlerts',
] satisfies (keyof github.RepositoryArgs)[]

export const repositoryOptions = (name: string): pulumi.CustomResourceOptions => ({
  ignoreChanges: preservedRepositoryInputs,
  // Fail closed on empty state: adopt this exact repository, never create a replacement.
  import: name,
  protect: true,
  retainOnDelete: true,
})

export const repositorySettings: Omit<github.RepositoryArgs, 'name'> = {
  allowAutoMerge: true,
  allowMergeCommit: true,
  allowRebaseMerge: false,
  allowSquashMerge: false,
  allowUpdateBranch: true,
  deleteBranchOnMerge: true,
  mergeCommitMessage: 'PR_TITLE',
  mergeCommitTitle: 'MERGE_MESSAGE',
  webCommitSignoffRequired: true,
}

export const defaultBranchRules = (requiredChecks: readonly string[]): github.types.input.RepositoryRulesetRules => ({
  deletion: true,
  nonFastForward: true,
  pullRequest: {
    allowedMergeMethods: ['merge'],
    dismissStaleReviewsOnPush: false,
    requireCodeOwnerReview: false,
    requireLastPushApproval: false,
    requiredApprovingReviewCount: 0,
    requiredReviewThreadResolution: false,
  },
  ...(Array.isReadonlyArrayNonEmpty(requiredChecks)
    ? {
        requiredStatusChecks: {
          doNotEnforceOnCreate: false,
          // GitHub Actions App ID, verified against GET /apps/github-actions.
          requiredChecks: requiredChecks.map((context) => ({ context, integrationId: 15_368 })),
          strictRequiredStatusChecksPolicy: false,
        },
      }
    : {}),
})
