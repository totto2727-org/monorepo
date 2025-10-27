import * as cloudflare from "@pulumi/cloudflare"
import * as group from "./access-group.js"
import * as config from "./config.js"

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
