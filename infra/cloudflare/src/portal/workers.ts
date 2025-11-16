import * as cloudflare from "@pulumi/cloudflare"
import * as config from "../config.js"

export const d1 = new cloudflare.D1Database(
  "portal-d1",
  {
    accountId: config.accountID,
    name: "portal",
    readReplication: {
      mode: "disabled",
    },
  },
  {
    protect: true,
  },
)
