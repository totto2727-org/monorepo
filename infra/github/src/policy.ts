import type * as github from '@pulumi/github'
import type * as pulumi from '@pulumi/pulumi'
import { Array } from 'effect'

export const repositoryOptions = (name: string): pulumi.CustomResourceOptions => ({
  // Fail closed on empty state: adopt this exact repository, never create a replacement.
  import: name,
  protect: true,
  retainOnDelete: true,
})

export const repositorySettings: Omit<github.RepositoryArgs, 'name'> = {
  allowAutoMerge: true,
  allowForking: true,
  allowMergeCommit: true,
  allowRebaseMerge: false,
  allowSquashMerge: false,
  allowUpdateBranch: true,
  archived: false,
  deleteBranchOnMerge: true,
  description: '',
  hasDiscussions: false,
  hasIssues: true,
  hasProjects: true,
  hasWiki: true,
  homepageUrl: '',
  isTemplate: false,
  mergeCommitMessage: 'PR_TITLE',
  mergeCommitTitle: 'MERGE_MESSAGE',
  securityAndAnalysis: {
    secretScanning: { status: 'disabled' },
    secretScanningNonProviderPatterns: { status: 'disabled' },
    secretScanningPushProtection: { status: 'disabled' },
  },
  topics: [],
  visibility: 'public',
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
