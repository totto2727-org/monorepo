import * as cloudflare from "@pulumi/cloudflare"
import * as config from "./config.ts"
import * as identityCenter from "./identity-center.ts"

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
