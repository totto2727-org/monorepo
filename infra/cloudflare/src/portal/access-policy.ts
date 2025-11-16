import * as cloudflare from "@pulumi/cloudflare"
import * as group from "../access-group.js"
import * as config from "../config.js"
import * as identityCenter from "../identity-provider.js"

export const mustBelongToPortalGroup = new cloudflare.ZeroTrustAccessPolicy(
  "must-belong-portal-group",
  {
    accountId: config.accountID,
    decision: "allow",
    includes: [
      {
        group: {
          id: group.saml.id,
        },
      },
    ],
    name: "Must belong to Portal group",
    requires: [
      {
        saml: {
          attributeName: "groups",
          attributeValue: config.awsPortalGroupID,
          identityProviderId: identityCenter.awsSaml.id,
        },
      },
    ],
    sessionDuration: "24h",
  },
  {
    protect: true,
  },
)
