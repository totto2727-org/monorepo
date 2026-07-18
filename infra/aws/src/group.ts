import * as aws from '@pulumi/aws'

import * as identifyStore from './identify-store.ts'

const createGroup = (name: string, displayName: string) =>
  new aws.identitystore.Group(
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

export const admin = createGroup('admin', 'Admin')

export const cloudflareAccess = createGroup('cloudflare-access', 'Cloudflare Access')
