export type MarketplaceKind = 'claude' | 'cursor' | 'codex'

interface KindConfig {
  readonly configDir: string
  readonly marketplacePath: string
}

const kindConfigs: Record<MarketplaceKind, KindConfig> = {
  claude: {
    configDir: '.claude-plugin',
    marketplacePath: '.claude-plugin/marketplace.json',
  },
  codex: {
    configDir: '.codex-plugin',
    marketplacePath: '.agents/plugins/marketplace.json',
  },
  cursor: {
    configDir: '.cursor-plugin',
    marketplacePath: '.cursor-plugin/marketplace.json',
  },
}

export const allKinds: readonly MarketplaceKind[] = ['claude', 'cursor', 'codex']

export const getKindConfig = (kind: MarketplaceKind): KindConfig => kindConfigs[kind]
