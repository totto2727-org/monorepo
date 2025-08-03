import type { DataSourceType } from "./types.js"

export async function save(
  bucket: R2Bucket,
  key: string,
  data: string,
  type: DataSourceType,
): Promise<void> {
  await bucket.put(key, data, {
    httpMetadata: {
      contentType: toMineType(type),
    },
  })
}

function toMineType(type: DataSourceType) {
  switch (type) {
    case "text":
      return "text/plain"
    case "firecrawl":
      return "text/markdown"
  }
}
