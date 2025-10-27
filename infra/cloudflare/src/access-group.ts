import * as cloudflare from "@pulumi/cloudflare"
import * as config from "./config.js"
import * as identityCenter from "./identity-provider.js"

export const saml = new cloudflare.ZeroTrustAccessGroup(
  "saml-access-group",
  {
    accountId: config.accountID,
    includes: [
      {
        loginMethod: {
          id: identityCenter.awsSaml.id,
        },
      },
    ],
    name: "SAML",
  },
  {
    protect: true,
  },
)
