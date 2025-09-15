import * as cloudflare from "@pulumi/cloudflare"
import * as group from "./access-group.ts"
import * as config from "./config.ts"

export const allowSaml = new cloudflare.ZeroTrustAccessPolicy(
  "must-authenticate-with-saml",
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
    name: "Must authenticate with SAML",
    sessionDuration: "24h",
  },
  {
    protect: true,
  },
)
