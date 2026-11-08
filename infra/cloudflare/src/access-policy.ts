import * as cloudflare from '@pulumi/cloudflare'

import * as group from './access-group.ts'
import * as config from './config.ts'

export const allowPasskeys = new cloudflare.ZeroTrustAccessPolicy(
  config.resourceName('must-authenticate-with-passkeys'),
  {
    accountId: config.accountID,
    decision: 'allow',
    includes: [{ group: { id: group.passkeyUsers.id } }],
    name: config.resourceName('must-authenticate-with-passkeys'),
    sessionDuration: '24h',
  },
  { protect: true },
)

export const allowSaml = new cloudflare.ZeroTrustAccessPolicy(
  config.resourceName('must-authenticate-with-saml'),
  {
    accountId: config.accountID,
    decision: 'allow',
    includes: [
      {
        group: {
          id: group.saml.id,
        },
      },
    ],
    name: config.resourceName('must-authenticate-with-saml'),
    sessionDuration: '24h',
  },
  config.protectedResourceOptions('must-authenticate-with-saml'),
)
