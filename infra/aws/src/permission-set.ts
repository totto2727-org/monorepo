import * as aws from '@pulumi/aws'

import * as identityStore from './identify-store.ts'

export const billing = new aws.ssoadmin.PermissionSet(
  'billing',
  {
    instanceArn: identityStore.arn,
    name: 'Billing',
    region: identityStore.region,
  },
  {
    protect: true,
  },
)

export const administratorAccess = new aws.ssoadmin.PermissionSet(
  'administrator-access',
  {
    instanceArn: identityStore.arn,
    name: 'AdministratorAccess',
    region: identityStore.region,
  },
  {
    protect: true,
  },
)
