export default {
  lint: {
    ignorePatterns: ['content/SKILL.md.ts'],
  },
  run: {
    tasks: {
      build: {
        command: 'mdts build',
        input: [{ auto: true }, '!dist/**'],
      },
    },
  },
}
