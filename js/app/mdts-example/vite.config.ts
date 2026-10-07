export default {
  lint: {
    ignorePatterns: ['content/SKILL.md.ts'],
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
