import * as cloudflare from '@pulumi/cloudflare'

import { allowSaml } from './access-policy.ts'
import * as config from './config.ts'
import { awsSaml } from './identity-provider.ts'

const tags = Object.entries(config.accessApplicationTags).map(
  ([key, name]) =>
    new cloudflare.ZeroTrustAccessTag(
      config.resourceName(`access-tag-${key}`),
      { accountId: config.accountID, name },
      { protect: true },
    ),
)

const createApplication = (name: string, domain: string) =>
  new cloudflare.ZeroTrustAccessApplication(
    config.resourceName(name),
    {
      accountId: config.accountID,
      allowedIdps: [awsSaml.id],
      appLauncherVisible: true,
      autoRedirectToIdentity: true,
      destinations: [{ type: 'public', uri: domain }],
      domain,
      name: config.resourceName(name),
      policies: [{ id: allowSaml.id, precedence: 1 }],
      sessionDuration: '24h',
      tags: tags.map((tag) => tag.name),
      type: 'self_hosted',
    },
    { protect: true },
  )

export const projektor = createApplication('projektor', 'projektor.totto2727.dev')
export const cloudflareOs = createApplication('cloudflare-os', 'cloudflare.totto2727.dev')

// More-specific Access applications override the hostname policy without changing its AUD.
// Keep MCP, OAuth authorization, the UI, and other APIs behind the existing SAML policy.
// Access path matching also covers child paths, so do not broaden /oauth/token with a wildcard.
// https://developers.cloudflare.com/cloudflare-one/access-controls/policies/app-paths/
export const projektorOAuthEndpoints = [
  ['discovery', 'projektor.totto2727.dev/.well-known/*'],
  ['token', 'projektor.totto2727.dev/oauth/token'],
].map(
  ([endpoint, domain]) =>
    new cloudflare.ZeroTrustAccessApplication(
      config.resourceName(`projektor-oauth-${endpoint}`),
      {
        accountId: config.accountID,
        appLauncherVisible: false,
        destinations: [{ type: 'public', uri: domain }],
        domain,
        name: config.resourceName(`projektor-oauth-${endpoint}`),
        policies: [
          {
            decision: 'bypass',
            includes: [{ everyone: {} }],
            name: config.resourceName(`projektor-oauth-${endpoint}`),
            precedence: 1,
          },
        ],
        tags: tags.map((tag) => tag.name),
        type: 'self_hosted',
      },
      { protect: true },
    ),
)

export const projektorAccessAudience = projektor.aud
export const projektorAccessDomain = projektor.domain
export const cloudflareOsAccessAudience = cloudflareOs.aud
export const cloudflareOsAccessDomain = cloudflareOs.domain
