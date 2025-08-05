// Mock data for development and testing purposes
// This should be replaced with actual API calls in production

export const mockMcpTools = [
  {
    createdAt: "2025-01-05T10:30:00Z",
    description: "Search Effect documentation and generate AI responses",
    id: "search_ai_effect",
    lastUsed: "2025-01-05T15:45:00Z",
    name: "search_ai_effect",
    target: "effect" as const,
    title: "Effect Documentation Search",
  },
]

export const mockDataSources = [
  {
    createdAt: "2025-01-05T10:30:00Z",
    id: "ds_001",
    sources: [
      {
        type: "text" as const,
        url: "https://effect.website/docs/getting-started",
      },
    ],
    target: "effect" as const,
    updatedAt: "2025-01-05T15:45:00Z",
  },
]

export const availableTargets = [{ label: "Effect", value: "effect" as const }]

export const availableDataSourceTypes = [
  { label: "Text", value: "text" as const },
  { label: "Firecrawl", value: "firecrawl" as const },
]

export const dashboardStats = {
  dataSourcesCount: mockDataSources.length,
  mcpToolsCount: mockMcpTools.length,
  updatedAt: "2025-01-05T10:30:00Z",
}
