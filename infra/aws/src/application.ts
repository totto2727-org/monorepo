import * as aws from "@pulumi/aws"
import * as group from "./group.ts"
import * as identityStore from "./identify-store.ts"

export const cloudflareAccess = new aws.ssoadmin.Application(
  "cloudflare-access-application",
  {
    applicationProviderArn: "arn:aws:sso::aws:applicationProvider/custom-saml",
    description: "Cloudflare Access",
    instanceArn: identityStore.arn,
    name: "Cloudflare Access",
    portalOptions: {
      signInOptions: {
        origin: "IDENTITY_CENTER",
      },
      visibility: "ENABLED",
    },
    region: identityStore.region,
    status: "ENABLED",
  },
  {
    protect: true,
  },
)

export const cloudflareApplicationAssignment =
  new aws.ssoadmin.ApplicationAssignment(
    "cloudflare-application-assignment",
    {
      applicationArn: cloudflareAccess.arn,
      principalId: group.cloudflareAccess.groupId,
      principalType: "GROUP",
      region: identityStore.region,
    },
    {
      protect: true,
    },
  )
