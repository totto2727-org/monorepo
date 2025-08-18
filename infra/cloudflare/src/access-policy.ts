import * as cloudflare from "@pulumi/cloudflare"
import * as group from "./access-group.ts"
import * as config from "./config.ts"

export const allowSaml = new cloudflare.ZeroTrustAccessPolicy(
  "allow-saml-policy",
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
    name: "SAML",
    sessionDuration: "24h",
  },
  {
    protect: true,
  },
)
