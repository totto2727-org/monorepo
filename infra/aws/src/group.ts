import * as aws from "@pulumi/aws"
import * as identifyStore from "./identify-store.ts"

export const admin = new aws.identitystore.Group(
  "admin",
  {
    displayName: "Admin",
    identityStoreId: identifyStore.id,
    region: identifyStore.region,
  },
  {
    protect: true,
  },
)

export const gitea = new aws.identitystore.Group(
  "gitea",
  {
    displayName: "Gitea",
    identityStoreId: identifyStore.id,
    region: identifyStore.region,
  },
  {
    protect: true,
  },
)

export const argocd = new aws.identitystore.Group(
  "argocd",
  {
    displayName: "Argo CD",
    identityStoreId: identifyStore.id,
    region: identifyStore.region,
  },
  {
    protect: true,
  },
)

export const cloudflareAccess = new aws.identitystore.Group(
  "cloudflare-access",
  {
    displayName: "Cloudflare Access",
    identityStoreId: identifyStore.id,
    region: identifyStore.region,
  },
  {
    protect: true,
  },
)

export const mcp = new aws.identitystore.Group(
  "mcp",
  {
    displayName: "MCP",
    identityStoreId: identifyStore.id,
    region: identifyStore.region,
  },
  {
    protect: true,
  },
)
