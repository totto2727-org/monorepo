import * as github from '@pulumi/github'

import { defaultBranchRules, repositoryOptions, repositorySettings } from './policy.ts'

const provider = new github.Provider('github', { owner: 'totto2727-org' })

const createRepository = (
  name: string,
  settings: github.RepositoryArgs = {},
  requiredChecks: readonly string[] = ['check'],
) => {
  const repository = new github.Repository(
    `repository-${name}`,
    { ...repositorySettings, ...settings, name },
    { ...repositoryOptions(name), provider },
  )
  const ruleset = new github.RepositoryRuleset(
    `default-branch-${name}`,
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
      rules: defaultBranchRules(requiredChecks),
      target: 'branch',
    },
    { protect: true, provider, retainOnDelete: true },
  )
  return { repository, ruleset }
}

export const workspace = createRepository(
  'workspace',
  {
    description: 'Virtual monorepo workspace for independent application and package repositories',
  },
  [],
)
export const agent = createRepository('agent', {
  description: 'Multi-product agent plugin marketplace for Claude Code, Cursor, and Codex',
})
export const monorepo = createRepository('monorepo', {
  hasProjects: false,
  hasWiki: false,
  securityAndAnalysis: {
    secretScanning: { status: 'enabled' },
    secretScanningNonProviderPatterns: { status: 'disabled' },
    secretScanningPushProtection: { status: 'enabled' },
  },
})
export const agentCoreSdk = createRepository('agent-core-sdk')
export const agentSdk = createRepository('agent-sdk')
export const codexSdk = createRepository('codex-sdk')
export const opencodeSdk = createRepository('opencode-sdk')
export const atlasToKysely = createRepository('atlas-to-kysely', {
  description: 'Generate Kysely type definitions from Atlas schemas',
})
export const cPlugin = createRepository('c-plugin', {
  description: 'A MoonBit CLI for managing agent plugins',
})
export const cloudflareOsStarter = createRepository(
  'cloudflare-os-starter',
  {
    description: 'A guide for customizing your Cloudflare OS deployment',
    hasIssues: false,
    hasWiki: false,
    homepageUrl: 'https://os.cloudflare.app',
  },
  [],
)
export const flowdeck = createRepository('flowdeck', {
  description: 'A local workflow cockpit for running, scheduling, and tracing graph-based workflows.',
})
export const glossshift = createRepository('glossshift')
export const mdts = createRepository('mdts', {}, [])
export const openConnector = createRepository(
  'open-connector',
  {
    description:
      'Open-source auth gateway connecting 1500+ SaaS providers to AI agents through SDK, CLI, MCP, HTTP, and OpenAPI.',
    hasIssues: false,
    hasWiki: false,
    homepageUrl: 'https://oomol.com',
  },
  ['Lint, Typecheck & Test'],
)
export const projektor = createRepository(
  'projektor',
  {
    description: 'Self hosted Wiki + Jira-style AI native issue tracker on Cloudflare Workers',
    hasIssues: false,
    homepageUrl: 'https://tajd.github.io/projektor/',
  },
  ['Test & type-check'],
)
export const reylo = createRepository(
  'reylo',
  {
    description: 'Import .sql files into TypeScript with full type inference and zero codegen.',
    hasIssues: false,
    homepageUrl: 'https://reylo.dev',
  },
  ['SQLite and HCL on ubuntu-latest', 'SQLite and HCL on windows-latest'],
)
export const admiral = createRepository('admiral', {
  description: 'Declarative CLI builder for MoonBit, inspired by gunshi',
  hasIssues: false,
})
export const llmProfiles = createRepository('llm-profiles', {
  description: 'Shared OpenAI-compatible agent configuration with optional Rust client adapters',
})
export const anyCollection = createRepository('any-collection')
export const oxlint = createRepository('oxlint', {
  description: 'Custom Oxlint rules and TypeScript / Effect presets for @totto2727/oxlint',
  homepageUrl: 'https://oxlint.totto2727.dev',
})
export const oxlintDocs = createRepository('oxlint-docs', {
  description: 'English and Japanese documentation for @totto2727/oxlint, built with Effront',
  homepageUrl: 'https://oxlint.totto2727.dev',
})
export const effront = createRepository('effront', {
  description: 'Effront is a React meta-framework built on Web standards and Effect.',
  hasIssues: false,
  hasWiki: false,
  homepageUrl: 'https://effront-docs-docs-production-6rpcuj2cm2urgl4w.totto2727.workers.dev/',
})
export const e2e = createRepository('e2e', {
  description: 'Reusable Go CLI end-to-end test helpers',
})
export const geo = createRepository('geo', {}, ['test'])
export const gitignorePatterns = createRepository('gitignore-patterns')
export const lens = createRepository('lens')
export const workgraph = createRepository('workgraph')
export const x = createRepository('x', {}, ['verify'])
export const templateGoSimple = createRepository('template-go-simple', {
  description: 'A simple Go CLI template with Nix, Just, and GitHub Actions',
  isTemplate: true,
  topics: ['go', 'just', 'nix', 'template'],
})
export const templateVitePlusLib = createRepository('template-vite-plus-lib', {
  description: 'A minimal Vite+ TypeScript library template with declarations and Nix development shell',
  isTemplate: true,
})
export const templateVitePlusApp = createRepository('template-vite-plus-app', {
  description: 'A minimal Vite+ TypeScript CLI template with Bun standalone executables and Nix packaging',
  isTemplate: true,
})
export const templateMoonbitSimple = createRepository('template-moonbit-simple', {
  description: 'A simple MoonBit library template with Nix and GitHub Actions',
  isTemplate: true,
  topics: ['moonbit', 'nix', 'template'],
})
export const templateRustSimple = createRepository('template-rust-simple', {
  description: 'A simple Rust library template with Nix, Just, and GitHub Actions',
  isTemplate: true,
  topics: ['just', 'nix', 'rust', 'template'],
})
export const templateHaskellSimple = createRepository('template-haskell-simple', {
  description: 'A simple Haskell CLI template with Nix, Cabal, and hpack',
  hasWiki: false,
  isTemplate: true,
})
export const moonbitOverlay = createRepository(
  'moonbit-overlay',
  {
    description: 'Reproducible nix overlay of binary distributed MoonBit toolchains and LSP',
    hasIssues: false,
    hasWiki: false,
  },
  ['flake-check'],
)
