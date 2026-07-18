import * as aws from '@pulumi/aws'
import type * as pulumi from '@pulumi/pulumi'

import * as group from './group.ts'
import * as identifyStore from './identify-store.ts'
import * as user from './user.ts'

const createGroupMembership = ({
  group: membershipGroup,
  user: membershipUser,
}: {
  readonly group: {
    readonly id: pulumi.Output<string>
    readonly name: string
  }
  readonly user: {
    readonly id: pulumi.Output<string>
    readonly name: string
  }
}) =>
  new aws.identitystore.GroupMembership(
    `${membershipGroup.name}-${membershipUser.name}`,
    {
      groupId: membershipGroup.id,
      identityStoreId: identifyStore.id,
      memberId: membershipUser.id,
      region: identifyStore.region,
    },
    {
      protect: true,
    },
  )

export const adminTotto2727 = createGroupMembership({
  group: {
    id: group.admin.groupId,
    name: 'admin',
  },
  user: {
    id: user.totto2727.userId,
    name: 'totto2727',
  },
})

export const cloudflareAccessTotto2727 = createGroupMembership({
  group: {
    id: group.cloudflareAccess.groupId,
    name: 'cloudflare-access',
  },
  user: {
    id: user.totto2727.userId,
    name: 'totto2727',
  },
})

export const cloudflareAccessTest = createGroupMembership({
  group: {
    id: group.cloudflareAccess.groupId,
    name: 'cloudflare-access',
  },
  user: {
    id: user.test.userId,
    name: 'test',
  },
})
