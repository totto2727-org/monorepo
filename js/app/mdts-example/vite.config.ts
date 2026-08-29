export default {
  run: {
    tasks: {
      build: {
        command: 'mdts build',
        input: [{ auto: true }, '!dist/**'],
      },
    },
  },
}
