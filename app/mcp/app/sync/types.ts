export type DataSourceType = "http" | "firecrawl"

export type DataSourceTarget = {
  type: DataSourceType
  url: URL
}

export type DataSourceConfig = {
  r2Bucket: R2Bucket
  dataSources: DataSourceTarget[]
}
