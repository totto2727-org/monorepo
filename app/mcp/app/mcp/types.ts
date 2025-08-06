export type McpSearchTool = {
  name: string
  title: string
  description: string
}

export type McpServerConfig = {
  name: string
  version: string
  ai: Ai
  sources: McpSearchTool[]
}
