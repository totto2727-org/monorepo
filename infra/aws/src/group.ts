import * as aws from "@pulumi/aws"
import * as identifyStore from "./identify-store.js"

function createGroup(name: string, displayName: string) {
  return new aws.identitystore.Group(
    name,
    {
      displayName,
      identityStoreId: identifyStore.id,
      region: identifyStore.region,
    },
    {
      protect: true,
    },
  )
}

export const admin = createGroup("admin", "Admin")

export const gitea = createGroup("gitea", "Gitea")

export const argocd = createGroup("argocd", "Argo CD")

export const cloudflareAccess = createGroup(
  "cloudflare-access",
  "Cloudflare Access",
)

export const mcp = createGroup("mcp", "MCP")

export const portal = createGroup("portal", "Portal")
