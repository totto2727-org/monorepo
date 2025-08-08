import { schema as dataSourceTypeSchema } from "./type/data-source-type.js"

export async function save(
  bucket: R2Bucket,
  key: string,
  data: string,
  type: typeof dataSourceTypeSchema.Type,
): Promise<void> {
  await bucket.put(addExtention(type, key), data, {
    httpMetadata: {
      contentType: toMineType(type),
    },
  })
}

function toMineType(type: typeof dataSourceTypeSchema.Type) {
  switch (type) {
    case "text":
      return "text/plain"
    case "firecrawl":
      return "text/markdown"
  }
}

function addExtention(type: typeof dataSourceTypeSchema.Type, key: string) {
  switch (type) {
    case "text":
      return [key, "txt"].join(".")
    case "firecrawl":
      return [key, "md"].join(".")
  }
}
