import { Predicate } from 'effect'

// oxlint-disable-next-line typescript/no-non-null-assertion -- restored environment contract is checked immediately below
export const accountID = process.env.CLOUDFLARE_ACCOUNT_ID!

if (Predicate.isNullish(accountID)) {
  throw new Error('required CLOUDFLARE_ACCOUNT_ID')
}
