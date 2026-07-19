import * as cloudflare from '@pulumi/cloudflare'

import * as config from './config.ts'
import * as identityCenter from './identity-provider.ts'

export const saml = new cloudflare.ZeroTrustAccessGroup(
  config.resourceName('saml-access-group'),
  {
    accountId: config.accountID,
    includes: [
      {
        loginMethod: {
          id: identityCenter.awsSaml.id,
        },
      },
    ],
    name: config.resourceName('saml'),
  },
  config.protectedResourceOptions('saml-access-group'),
)
