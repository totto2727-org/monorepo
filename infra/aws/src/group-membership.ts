import * as aws from "@pulumi/aws"
import * as group from "./group.ts"
import * as identifyStore from "./identify-store.ts"
import * as user from "./user.ts"

export const giteaTotto2727 = new aws.identitystore.GroupMembership(
  "gitea-totto2727",
  {
    groupId: group.gitea.groupId,
    identityStoreId: identifyStore.id,
    memberId: user.totto2727.userId,
    region: identifyStore.region,
  },
  {
    protect: true,
  },
)

export const adminTotto2727 = new aws.identitystore.GroupMembership(
  "admin-totto2727",
  {
    groupId: group.admin.groupId,
    identityStoreId: identifyStore.id,
    memberId: user.totto2727.userId,
    region: identifyStore.region,
  },
  {
    protect: true,
  },
)

export const argocdTotto2727 = new aws.identitystore.GroupMembership(
  "argocd-totto2727",
  {
    groupId: group.argocd.groupId,
    identityStoreId: identifyStore.id,
    memberId: user.totto2727.userId,
    region: identifyStore.region,
  },
  {
    protect: true,
  },
)

export const cloudflareAccessTotto2727 = new aws.identitystore.GroupMembership(
  "cloudflare-access-totto2727",
  {
    groupId: group.cloudflareAccess.groupId,
    identityStoreId: identifyStore.id,
    memberId: user.totto2727.userId,
    region: identifyStore.region,
  },
  {
    protect: true,
  },
)
