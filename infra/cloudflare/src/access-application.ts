import * as cloudflare from '@pulumi/cloudflare'
import * as pulumi from '@pulumi/pulumi'

import { allowDeploymentAdmin } from './access-policy.ts'
import * as config from './config.ts'
import { awsSaml } from './identity-provider.ts'

const settings = new pulumi.Config('access')
const projektorDomain = settings.require('projektorDomain')
const cloudflareOsDomain = settings.require('cloudflareOsDomain')

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
      policies: [{ id: allowDeploymentAdmin.id, precedence: 1 }],
      sessionDuration: '24h',
      tags: tags.map((tag) => tag.name),
      type: 'self_hosted',
    },
    { protect: true },
  )

export const projektor = createApplication('projektor', projektorDomain)
export const cloudflareOs = createApplication('cloudflare-os', cloudflareOsDomain)

export const projektorAccessAudience = projektor.aud
export const projektorAccessDomain = projektor.domain
export const cloudflareOsAccessAudience = cloudflareOs.aud
export const cloudflareOsAccessDomain = cloudflareOs.domain
