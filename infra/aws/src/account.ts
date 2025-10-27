import * as aws from "@pulumi/aws"
import * as group from "./group.js"
import * as identityStore from "./identify-store.js"
import * as permissionSet from "./permission-set.js"

export const totto2727 = new aws.organizations.Account(
  "totto2727-account",
  {
    // Enable on next create
    // closeOnDeletion: false,
    // createGovcloud: false,
    // iamUserAccessToBilling: "ALLOW",
    email: "kaihatu.totto2727@gmail.com",
    name: "totto2727",
    parentId: "r-n63z",
  },
  {
    protect: true,
  },
)

export const totto2727AdminGroupAdministratorPermissionSet =
  new aws.ssoadmin.AccountAssignment(
    "admin-administrator-permission-set",
    {
      instanceArn: identityStore.arn,
      permissionSetArn: permissionSet.administratorAccess.arn,
      principalId: group.admin.groupId,
      principalType: "GROUP",
      region: identityStore.region,
      targetId: totto2727.id,
      targetType: "AWS_ACCOUNT",
    },
    {
      protect: true,
    },
  )

export const totto2727AdminGroupBillingPermissionSet =
  new aws.ssoadmin.AccountAssignment(
    "admin-billing-permission-set",
    {
      instanceArn: identityStore.arn,
      permissionSetArn: permissionSet.billing.arn,
      principalId: group.admin.groupId,
      principalType: "GROUP",
      region: identityStore.region,
      targetId: totto2727.id,
      targetType: "AWS_ACCOUNT",
    },
    {
      protect: true,
    },
  )
