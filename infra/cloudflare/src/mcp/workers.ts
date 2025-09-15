import * as cloudflare from "@pulumi/cloudflare";
import * as config from "../config.ts"

export const r2 = new cloudflare.R2Bucket("mcp-r2", {
  accountId: config.accountID,
  jurisdiction: "default",
  location: "APAC",
  name: "mcp",
  storageClass: "Standard",
}, {
  protect: true,
});

export const r2LifeCycle = new cloudflare.R2BucketLifecycle("mcp-r2-lifecycle", {
  accountId: config.accountID,
  bucketName: r2.name,
  jurisdiction: r2.jurisdiction,
  rules: [
    {
      conditions: {
        prefix: ""
      },
      id: "Auto Delete",
      enabled: true,
      deleteObjectsTransition: {
        condition: {
          type: "Age",
          maxAge: 14 * 24 * 60 * 60
        },
      },
    },
    {
      conditions: {
        prefix: ""
      },
      id: "Default Multipart Abort Rule",
      enabled: true,
      abortMultipartUploadsTransition: {
        condition: {
          type: "Age",
          maxAge: 7 * 24 * 60 * 60
        }
      }
    }
  ]
})

export const d1 = new cloudflare.D1Database("mcp-d1", {
  accountId: config.accountID,
  name: "mcp",
  readReplication: {
    mode: "disabled",
  },
  primaryLocationHint: "apac"
}, {
  protect: true,
});

export const kv = new cloudflare.WorkersKvNamespace("mcp-kv", {
  accountId: config.accountID,
  title: "mcp-oauth",
}, {
  protect: true,
});
