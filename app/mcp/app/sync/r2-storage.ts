import type { DataSourceType } from "./types.js"

export async function save(
  bucket: R2Bucket,
  key: string,
  data: string,
  type: DataSourceType,
): Promise<void> {
  await bucket.put(addExtention(type, key), data, {
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

function addExtention(type: DataSourceType, key: string) {
  switch (type) {
    case "text":
      return [key, "txt"].join(".")
    case "firecrawl":
      return [key, "md"].join(".")
  }
}
