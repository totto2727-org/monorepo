import { DATETIME } from "@package/constant"
import * as cloudflare from "@pulumi/cloudflare"
import * as config from "../config.js"

export const r2 = new cloudflare.R2Bucket(
  "mcp-r2",
  {
    accountId: config.accountID,
    jurisdiction: "default",
    location: "APAC",
    name: "mcp",
    storageClass: "Standard",
  },
  {
    protect: true,
  },
)

export const r2LifeCycle = new cloudflare.R2BucketLifecycle(
  "mcp-r2-lifecycle",
  {
    accountId: config.accountID,
    bucketName: r2.name,
    jurisdiction: r2.jurisdiction,
    rules: [
      {
        conditions: {
          prefix: "",
        },
        deleteObjectsTransition: {
          condition: {
            maxAge:
              2 *
              DATETIME.ONE_WEEK_IN_DAYS *
              DATETIME.ONE_DAY_IN_HOURS *
              DATETIME.ONE_HOUR_IN_MINUTES *
              DATETIME.ONE_MINUTE_IN_SECONDS,
            type: "Age",
          },
        },
        enabled: true,
        id: "Auto Delete",
      },
      {
        abortMultipartUploadsTransition: {
          condition: {
            maxAge:
              DATETIME.ONE_WEEK_IN_DAYS *
              DATETIME.ONE_DAY_IN_HOURS *
              DATETIME.ONE_HOUR_IN_MINUTES *
              DATETIME.ONE_MINUTE_IN_SECONDS,
            type: "Age",
          },
        },
        conditions: {
          prefix: "",
        },
        enabled: true,
        id: "Default Multipart Abort Rule",
      },
    ],
  },
)

export const d1 = new cloudflare.D1Database(
  "mcp-d1",
  {
    accountId: config.accountID,
    name: "mcp",
    primaryLocationHint: "apac",
    readReplication: {
      mode: "disabled",
    },
  },
  {
    protect: true,
  },
)

export const kv = new cloudflare.WorkersKvNamespace(
  "mcp-kv",
  {
    accountId: config.accountID,
    title: "mcp-oauth",
  },
  {
    protect: true,
  },
)
