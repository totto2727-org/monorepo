import * as aws from "@pulumi/aws"
import type * as pulumi from "@pulumi/pulumi"
import * as group from "./group.js"
import * as identifyStore from "./identify-store.js"
import * as user from "./user.js"

function createGroupMembership({
  // biome-ignore lint/nursery/noShadow: shadowing is intended
  group,
  // biome-ignore lint/nursery/noShadow: shadowing is intended
  user,
}: {
  group: {
    id: pulumi.Output<string>
    name: string
  }
  user: {
    id: pulumi.Output<string>
    name: string
  }
}) {
  return new aws.identitystore.GroupMembership(
    `${group.name}-${user.name}`,
    {
      groupId: group.id,
      identityStoreId: identifyStore.id,
      memberId: user.id,
      region: identifyStore.region,
    },
    {
      protect: true,
    },
  )
}

export const giteaTotto2727 = createGroupMembership({
  group: {
    id: group.gitea.groupId,
    name: "gitea",
  },
  user: {
    id: user.totto2727.userId,
    name: "totto2727",
  },
})

export const adminTotto2727 = createGroupMembership({
  group: {
    id: group.admin.groupId,
    name: "admin",
  },
  user: {
    id: user.totto2727.userId,
    name: "totto2727",
  },
})

export const argocdTotto2727 = createGroupMembership({
  group: {
    id: group.argocd.groupId,
    name: "argocd",
  },
  user: {
    id: user.totto2727.userId,
    name: "totto2727",
  },
})
export const cloudflareAccessTotto2727 = createGroupMembership({
  group: {
    id: group.cloudflareAccess.groupId,
    name: "cloudflare-access",
  },
  user: {
    id: user.totto2727.userId,
    name: "totto2727",
  },
})

export const mcpTotto2727 = createGroupMembership({
  group: {
    id: group.mcp.groupId,
    name: "mcp",
  },
  user: {
    id: user.totto2727.userId,
    name: "totto2727",
  },
})

export const portalTotto2727 = createGroupMembership({
  group: {
    id: group.portal.groupId,
    name: "portal",
  },
  user: {
    id: user.totto2727.userId,
    name: "totto2727",
  },
})

export const cloudflareAccessTest = createGroupMembership({
  group: {
    id: group.cloudflareAccess.groupId,
    name: "cloudflare-access",
  },
  user: {
    id: user.test.userId,
    name: "test",
  },
})
