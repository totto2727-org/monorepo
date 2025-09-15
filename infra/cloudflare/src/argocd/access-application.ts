import * as cloudflare from "@pulumi/cloudflare"
import * as policy from "../access-policy.ts"
import * as config from "../config.ts"
import * as identityCenter from "../identity-provider.ts"

export const oidc = new cloudflare.ZeroTrustAccessApplication(
  "argocd",
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
