import * as aws from '@pulumi/aws'

import * as group from './group.ts'
import * as identityStore from './identify-store.ts'
import * as permissionSet from './permission-set.ts'

export const totto2727 = new aws.organizations.Account(
  'totto2727-account',
  {
    // Enable on next create
    // closeOnDeletion: false,
    // createGovcloud: false,
    // iamUserAccessToBilling: "ALLOW",
    email: 'kaihatu.totto2727@gmail.com',
    name: 'totto2727',
    parentId: 'r-n63z',
  },
  {
    protect: true,
  },
)

export const totto2727AdminGroupAdministratorPermissionSet = new aws.ssoadmin.AccountAssignment(
  'admin-administrator-permission-set',
  {
    instanceArn: identityStore.arn,
    permissionSetArn: permissionSet.administratorAccess.arn,
    principalId: group.admin.groupId,
    principalType: 'GROUP',
    region: identityStore.region,
    targetId: totto2727.id,
    targetType: 'AWS_ACCOUNT',
  },
  {
    protect: true,
  },
)

export const totto2727AdminGroupBillingPermissionSet = new aws.ssoadmin.AccountAssignment(
  'admin-billing-permission-set',
  {
    instanceArn: identityStore.arn,
    permissionSetArn: permissionSet.billing.arn,
    principalId: group.admin.groupId,
    principalType: 'GROUP',
    region: identityStore.region,
    targetId: totto2727.id,
    targetType: 'AWS_ACCOUNT',
  },
  {
    protect: true,
  },
)

export const administratorAccessPolicy = new aws.ssoadmin.ManagedPolicyAttachment(
  'administrator-access-policy',
  {
    instanceArn: identityStore.arn,
    managedPolicyArn: 'arn:aws:iam::aws:policy/AdministratorAccess',
    permissionSetArn: permissionSet.administratorAccess.arn,
    region: identityStore.region,
  },
  {
    dependsOn: [totto2727AdminGroupAdministratorPermissionSet],
    protect: true,
  },
)

export const billingPolicy = new aws.ssoadmin.ManagedPolicyAttachment(
  'billing-policy',
  {
    instanceArn: identityStore.arn,
    managedPolicyArn: 'arn:aws:iam::aws:policy/job-function/Billing',
    permissionSetArn: permissionSet.billing.arn,
    region: identityStore.region,
  },
  {
    dependsOn: [totto2727AdminGroupBillingPermissionSet],
    protect: true,
  },
)
