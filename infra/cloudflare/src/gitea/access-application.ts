import * as cloudflare from "@pulumi/cloudflare"
import * as policy from "../access-policy.js"
import * as config from "../config.js"
import * as identityCenter from "../identity-provider.js"

export const oidc = new cloudflare.ZeroTrustAccessApplication(
  "gitea",
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
