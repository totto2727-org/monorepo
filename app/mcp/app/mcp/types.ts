export type TargetDocument = "effect"

export type McpSearchTool = {
  name: string
  title: string
  description: string
  target: TargetDocument
}

export type McpServerConfig = {
  name: string
  version: string
  ai: Ai
  sources: McpSearchTool[]
}
