import * as aws from '@pulumi/aws'

import * as config from './config.ts'
import * as group from './group.ts'
import * as identityStore from './identify-store.ts'

// This application must be created manually in AWS IAM Identity Center.
// Remember to configure its attribute mappings under Applications.
// Download the Cloudflare Access SAML metadata from:
// https://totto2727.cloudflareaccess.com/cdn-cgi/access/saml-metadata
export const cloudflareAccess = new aws.ssoadmin.Application(
  config.resourceName('cloudflare-access-application'),
  {
    applicationProviderArn: 'arn:aws:sso::aws:applicationProvider/custom-saml',
    description: 'Cloudflare Access',
    instanceArn: identityStore.arn,
    name: config.resourceName('cloudflare-access'),
    portalOptions: {
      signInOptions: {
        origin: 'IDENTITY_CENTER',
      },
      visibility: 'ENABLED',
    },
    region: identityStore.region,
    status: 'ENABLED',
  },
  config.protectedResourceOptions('cloudflare-access-application'),
)

export const cloudflareApplicationAssignment = new aws.ssoadmin.ApplicationAssignment(
  config.resourceName('cloudflare-application-assignment'),
  {
    applicationArn: cloudflareAccess.arn,
    principalId: group.cloudflareAccess.groupId,
    principalType: 'GROUP',
    region: identityStore.region,
  },
  config.protectedResourceOptions('cloudflare-application-assignment'),
)
