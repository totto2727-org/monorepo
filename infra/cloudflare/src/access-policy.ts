import * as cloudflare from "@pulumi/cloudflare"
import * as group from "./access-group.ts"
import * as config from "./config.ts"
import * as identityCenter from "./identity-provider.ts"

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

export const mcp = new cloudflare.ZeroTrustAccessPolicy(
  "mcp-policy",
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
    name: "MCP",
    requires: [
      {
        saml: {
          attributeName: "groups",
          attributeValue: config.awsMcpGroupID,
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
