// https://github.com/oven-sh/bun/issues/24356#issuecomment-3877275486
import * as babel from '@babel/core'
import { Predicate } from '@totto2727/fp/effect'
import BabelPluginReactCompiler from 'babel-plugin-react-compiler'

const options = {}

const reactCompiler: Bun.BunPlugin = {
  name: 'react-compiler',
  setup({ onLoad }) {
    onLoad({ filter: /\.[jt]sx$/ }, async (args) => {
      const input = await Bun.file(args.path).text()
      const result = await babel.transformAsync(input, {
        ast: false,
        babelrc: false,
        configFile: false,
        filename: args.path,
        parserOpts: { plugins: ['jsx', 'typescript'] },
        plugins: [[BabelPluginReactCompiler, options]],
        sourceMaps: Bun.env.NODE_ENV === 'development',
      })

      if (Predicate.isNullable(result?.code)) {
        throw new Error(`Failed to compile ${args.path}`)
      }

      return { contents: result.code, loader: 'tsx' }
    })
  },
}

export default reactCompiler
