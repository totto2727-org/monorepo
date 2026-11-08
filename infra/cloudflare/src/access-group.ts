import * as cloudflare from '@pulumi/cloudflare'

import * as config from './config.ts'
import * as identityCenter from './identity-provider.ts'

export const passkeyUsers = new cloudflare.ZeroTrustAccessGroup(
  config.resourceName('passkey-users-access-group'),
  {
    accountId: config.accountID,
    // Preserve the members currently assigned to the AWS Cloudflare Access application.
    includes: [{ email: { email: 'kaihatu.totto2727@gmail.com' } }, { email: { email: 'hayato.2000.0727@gmail.com' } }],
    name: config.resourceName('passkey-users'),
    requires: [{ loginMethod: { id: identityCenter.passkeys.id } }],
  },
  { protect: true },
)

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
