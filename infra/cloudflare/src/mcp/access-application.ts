import * as cloudflare from "@pulumi/cloudflare"
import * as config from "../config.js"
import * as identityCenter from "../identity-provider.js"
import * as policy from "./access-policy.js"

export const adminConsole = new cloudflare.ZeroTrustAccessApplication(
  "mcp-admin-console",
  {
    accountId: config.accountID,
    allowedIdps: [identityCenter.awsSaml.id],
    appLauncherVisible: true,
    autoRedirectToIdentity: true,
    domain: "mcp.totto2727.workers.dev/app",
    name: "MCP Admin Console",
    policies: [
      {
        id: policy.mustBelongToMCPGroup.id,
      },
    ],
    selfHostedDomains: [
      "mcp.totto2727.workers.dev/app",
      "*-mcp.totto2727.workers.dev/app",
    ],
    sessionDuration: "24h",
    type: "self_hosted",
  },
  {
    protect: false,
  },
)

export const server = new cloudflare.ZeroTrustAccessApplication(
  "mcp-server",
  {
    accountId: config.accountID,
    allowedIdps: [identityCenter.awsSaml.id],
    appLauncherVisible: true,
    autoRedirectToIdentity: true,
    name: "MCP Server",
    policies: [
      {
        id: policy.mustBelongToMCPGroup.id,
      },
    ],
    saasApp: {
      accessTokenLifetime: "5m",
      appLauncherUrl: "https://mcp.totto2727.workers.dev/app/admin",
      authType: "oidc",
      grantTypes: ["authorization_code", "refresh_tokens"],
      redirectUris: ["https://mcp.totto2727.workers.dev/callback"],
      refreshTokenOptions: {
        lifetime: "90d",
      },
      scopes: ["openid", "email", "profile", "groups"],
    },
    sessionDuration: "24h",
    type: "saas",
  },
  {
    protect: true,
  },
)
