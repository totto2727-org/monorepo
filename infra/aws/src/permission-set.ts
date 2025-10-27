import * as aws from "@pulumi/aws"
import * as identityStore from "./identify-store.js"

export const billing = new aws.ssoadmin.PermissionSet(
  "billing",
  {
    instanceArn: identityStore.arn,
    name: "Billing",
    region: identityStore.region,
  },
  {
    protect: true,
  },
)

export const billingPolicy = new aws.ssoadmin.ManagedPolicyAttachment(
  "billing-policy",
  {
    instanceArn: identityStore.arn,
    managedPolicyArn: "arn:aws:iam::aws:policy/job-function/Billing",
    permissionSetArn: billing.arn,
    region: identityStore.region,
  },
  {
    protect: true,
  },
)

export const administratorAccess = new aws.ssoadmin.PermissionSet(
  "administrator-access",
  {
    instanceArn: identityStore.arn,
    name: "AdministratorAccess",
    region: identityStore.region,
  },
  {
    protect: true,
  },
)

export const administratorAccessPolicy =
  new aws.ssoadmin.ManagedPolicyAttachment(
    "administrator-access-policy",
    {
      instanceArn: identityStore.arn,
      managedPolicyArn: "arn:aws:iam::aws:policy/AdministratorAccess",
      permissionSetArn: administratorAccess.arn,
      region: identityStore.region,
    },
    {
      protect: true,
    },
  )
