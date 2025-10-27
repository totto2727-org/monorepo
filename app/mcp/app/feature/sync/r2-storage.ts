import { Match } from "@totto/function/effect"
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
  return Match.value(type).pipe(
    Match.when("text", () => "text/plain"),
    Match.when("firecrawl", () => "text/markdown"),
    Match.exhaustive,
  )
}

function addExtention(type: typeof DataSourceType.schema.Type, key: string) {
  return Match.value(type).pipe(
    Match.when("text", () => [key, "txt"].join(".")),
    Match.when("firecrawl", () => [key, "md"].join(".")),
    Match.exhaustive,
  )
}
