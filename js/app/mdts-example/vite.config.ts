import { generateIgnorePatterns } from '@totto2727/gitignore-patterns'

const ignorePatterns = await generateIgnorePatterns(new URL('.', import.meta.url))

export default {
  lint: {
    ignorePatterns: [...ignorePatterns, 'content/SKILL.md.ts'],
  },
  run: {
    tasks: {
      build: {
        cache: { input: [{ auto: true }, '!dist/**'] },
        command: 'mdts build',
      },
    },
  },
}
