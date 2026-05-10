import type { StorybookConfig } from '@storybook/react-vite'

const config: StorybookConfig = {
  addons: [],
  framework: {
    name: '@storybook/react-vite',
    options: {},
  },
  stories: ['../src/**/*.stories.@(js|jsx|mjs|ts|tsx)'],
  // oxlint-disable-next-line no-shadow -- viteFinal callback parameter mirrors the outer config name by Storybook convention
  async viteFinal(config) {
    const { default: tailwindcss } = await import('@tailwindcss/vite')
    config.plugins = config.plugins ?? []
    config.plugins.push(tailwindcss())
    return config
  },
}
export default config
