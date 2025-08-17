import * as aws from "@pulumi/aws"

const identifyStore = await aws.ssoadmin.getInstances({})

// biome-ignore lint/style/noNonNullAssertion: required
export const id = identifyStore.identityStoreIds[0]!
export const region = identifyStore.region
// biome-ignore lint/style/noNonNullAssertion: required
export const arn = identifyStore.arns[0]!
