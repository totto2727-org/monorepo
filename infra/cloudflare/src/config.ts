import { Predicate } from "@totto/function/effect"

// biome-ignore lint/style/noNonNullAssertion: required
export const accountID = process.env.CLOUDFLARE_ACCOUNT_ID!

if (Predicate.isNullable(accountID)) {
  throw new Error("required CLOUDFLARE_ACCOUNT_ID")
}
