import * as cloudflare from "@pulumi/cloudflare"
import * as policy from "./access-policy.ts"
import * as config from "./config.ts"
import * as identityCenter from "./identity-provider.ts"

export const gitea = new cloudflare.ZeroTrustAccessApplication(
  "gitea-application",
  {
    accountId: config.accountID,
    allowedIdps: [identityCenter.awsSaml.id],
    appLauncherVisible: true,
    autoRedirectToIdentity: true,
    name: "Gitea",
    policies: [
      {
        id: policy.allowSaml.id,
      },
    ],
    saasApp: {
      accessTokenLifetime: "5m",
      appLauncherUrl: "https://gitea.totto2727.dev/user/login?redirect_to=/",
      authType: "oidc",
      grantTypes: ["authorization_code_with_pkce"],
      redirectUris: [
        "https://gitea.totto2727.dev/user/oauth2/Cloudflare%20Access/callback",
      ],
      scopes: ["openid", "email", "profile", "groups"],
    },
    sessionDuration: "24h",
    type: "saas",
  },
  {
    protect: true,
  },
)

export const argocd = new cloudflare.ZeroTrustAccessApplication(
  "argocd-application",
  {
    accountId: config.accountID,
    allowedIdps: [identityCenter.awsSaml.id],
    appLauncherVisible: true,
    autoRedirectToIdentity: true,
    name: "Argo CD",
    policies: [
      {
        id: policy.allowSaml.id,
      },
    ],
    saasApp: {
      accessTokenLifetime: "5m",
      appLauncherUrl: "https://argocd.totto2727.dev/applications",
      authType: "oidc",
      grantTypes: ["authorization_code"],
      redirectUris: ["https://argocd.totto2727.dev/api/dex/callback"],
      scopes: ["openid", "email", "profile", "groups"],
    },
    sessionDuration: "24h",
    type: "saas",
  },
  {
    protect: true,
  },
)

export const mcp = new cloudflare.ZeroTrustAccessApplication(
  "mcp-application",
  {
    accountId: config.accountID,
    allowedIdps: [identityCenter.awsSaml.id],
    appLauncherVisible: true,
    autoRedirectToIdentity: true,
    domain: "mcp.totto2727.workers.dev/app",
    name: "mcp.totto2727.workers.dev",
    policies: [
      {
        id: policy.mcp.id,
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
    protect: true,
  },
)

export const mcpOidc = new cloudflare.ZeroTrustAccessApplication(
  "mcp-oidc-application",
  {
    accountId: config.accountID,
    allowedIdps: [identityCenter.awsSaml.id],
    appLauncherVisible: true,
    autoRedirectToIdentity: true,
    name: "MCP OIDC",
    policies: [
      {
        id: policy.mcp.id,
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
