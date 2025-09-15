import * as cloudflare from "@pulumi/cloudflare"
import * as group from "../access-group.ts"
import * as config from "../config.ts"
import * as identityCenter from "../identity-provider.ts"

export const mustBelongToMCPGroup = new cloudflare.ZeroTrustAccessPolicy(
  "must-belong-mcp-group",
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
    name: "Must belong to MCP group",
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
