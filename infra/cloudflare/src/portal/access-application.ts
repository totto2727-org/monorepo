import * as cloudflare from "@pulumi/cloudflare"
import * as config from "../config.js"
import * as identityCenter from "../identity-provider.js"
import * as policy from "./access-policy.js"

export const adminConsole = new cloudflare.ZeroTrustAccessApplication(
  "portal-admin-console",
  {
    accountId: config.accountID,
    allowedIdps: [identityCenter.awsSaml.id],
    appLauncherVisible: true,
    autoRedirectToIdentity: true,
    domain: "portal.totto2727.workers.dev",
    name: "Portal",
    policies: [
      {
        id: policy.mustBelongToPortalGroup.id,
      },
    ],
    selfHostedDomains: [
      "portal.totto2727.workers.dev",
      "*-portal.totto2727.workers.dev",
    ],
    sessionDuration: "24h",
    type: "self_hosted",
  },
  {
    protect: true,
  },
)
