import type * as DataSourceType from "./type/data-source-type.js"

export async function save(
  bucket: R2Bucket,
  key: string,
  data: string,
  type: typeof DataSourceType.schema.Type,
): Promise<void> {
  await bucket.put(addExtention(type, key), data, {
    httpMetadata: {
      contentType: toMineType(type),
    },
  })
}

function toMineType(type: typeof DataSourceType.schema.Type) {
  // biome-ignore lint/style/useDefaultSwitchClause: No use default switch clause
  switch (type) {
    case "text":
      return "text/plain"
    case "firecrawl":
      return "text/markdown"
  }
}

function addExtention(type: typeof DataSourceType.schema.Type, key: string) {
  // biome-ignore lint/style/useDefaultSwitchClause: No use default switch clause
  switch (type) {
    case "text":
      return [key, "txt"].join(".")
    case "firecrawl":
      return [key, "md"].join(".")
  }
}
