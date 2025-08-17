import * as aws from "@pulumi/aws"
import * as identifyStore from "./identify-store.ts"

export const totto2727 = new aws.identitystore.User(
  "totto2727",
  {
    displayName: "土田 快斗",
    emails: {
      primary: true,
      type: "work",
      value: "kaihatu.totto2727@gmail.com",
    },
    identityStoreId: identifyStore.id,
    name: {
      familyName: "土田",
      givenName: "快斗",
    },
    region: identifyStore.region,
    userName: "totto2727",
  },
  {
    protect: true,
  },
)
