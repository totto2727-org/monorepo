import * as pulumi from "@pulumi/pulumi"
import { Predicate } from "@totto/function/effect"

// biome-ignore lint/style/noNonNullAssertion: required
export const accountID = process.env.CLOUDFLARE_ACCOUNT_ID!

if (Predicate.isNullable(accountID)) {
  throw new Error("required CLOUDFLARE_ACCOUNT_ID")
}

const config = new pulumi.Config()
const org = config.require("org")
const stack = pulumi.getStack()
const awsStackRef = new pulumi.StackReference(`${org}/aws/${stack}`)

export const awsMcpGroupID = awsStackRef.requireOutput("mcpGroupId")
