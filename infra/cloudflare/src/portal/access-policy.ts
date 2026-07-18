import * as cloudflare from '@pulumi/cloudflare'

import * as group from '../access-group.ts'
import * as config from '../config.ts'
import * as identityCenter from '../identity-provider.ts'

export const mustBelongToPortalGroup = new cloudflare.ZeroTrustAccessPolicy(
  'must-belong-portal-group',
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
    name: 'Must belong to Portal group',
    requires: [
      {
        saml: {
          attributeName: 'groups',
          attributeValue: config.awsPortalGroupID,
          identityProviderId: identityCenter.awsSaml.id,
        },
      },
    ],
    sessionDuration: '24h',
  },
  {
    protect: true,
  },
)
