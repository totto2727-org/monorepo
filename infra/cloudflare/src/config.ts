import * as pulumi from '@pulumi/pulumi'
import { Predicate } from 'effect'

export const accountID = (() => {
  const value = process.env.CLOUDFLARE_ACCOUNT_ID

  if (Predicate.isNullish(value)) {
    throw new TypeError('CLOUDFLARE_ACCOUNT_ID is required')
  }

  return value
})()

const stack = pulumi.getStack()
const awsStackRef = new pulumi.StackReference(`totto2727/aws/${stack}`)

export const awsMcpGroupID = awsStackRef.requireOutput('mcpGroupId')
export const awsPortalGroupID = awsStackRef.requireOutput('portalGroupId')
