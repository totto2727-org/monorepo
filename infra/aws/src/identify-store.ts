import * as aws from '@pulumi/aws'
import { Predicate } from 'effect'

const identifyStore = await aws.ssoadmin.getInstances({})

export const { arn, id, region } = (() => {
  const {
    arns: [identityStoreArn],
    identityStoreIds: [identityStoreID],
    region: identityStoreRegion,
  } = identifyStore

  if (Predicate.isNullish(identityStoreID) || Predicate.isNullish(identityStoreArn)) {
    throw new TypeError('AWS IAM Identity Center instance is required')
  }

  return {
    arn: identityStoreArn,
    id: identityStoreID,
    region: identityStoreRegion,
  }
})()
