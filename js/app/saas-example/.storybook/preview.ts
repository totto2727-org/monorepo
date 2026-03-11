import type { Preview } from '@storybook/react-vite'

// oxlint-disable-next-line eslint-plugin-import(no-relative-parent-imports
import '../src/styles.css'

const preview: Preview = {
  parameters: {
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
  },
}

export default preview
