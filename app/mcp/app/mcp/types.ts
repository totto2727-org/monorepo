export type McpServerConfig = {
  name: string
  version: string
  ai: Ai
  autoRagName: string
  aiSearch: {
    name: string
    title: string
    description: string
  }
}
