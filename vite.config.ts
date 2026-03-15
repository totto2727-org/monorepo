import { defineConfig } from 'vite-plus'

export default defineConfig({
  fmt: {
    arrowParens: 'always',
    bracketSameLine: false,
    bracketSpacing: true,
    endOfLine: 'lf',
    experimentalSortImports: {
      ignoreCase: true,
      newlinesBetween: true,
      order: 'asc',
    },
    experimentalSortPackageJson: true,
    jsxSingleQuote: true,
    printWidth: 120,
    quoteProps: 'as-needed',
    semi: false,
    singleQuote: true,
    tabWidth: 2,
    trailingComma: 'all',
    useTabs: false,
  },
  staged: {
    '*': 'vp run fix',
  },
})
// lint: {
//   extends: [
//     "./node_modules/ultracite/config/oxlint/core/.oxlintrc.json",
//     "./node_modules/ultracite/config/oxlint/react/.oxlintrc.json",
//     "./node_modules/ultracite/config/oxlint/remix/.oxlintrc.json",
//   ],
//   rules: {
//     "func-names": [
//       "error",
//       "always",
//       {
//         generators: "never",
//       },
//     ],
//     "number-literal-case": "allow",
//     "import/extensions": [
//       "error",
//       "always",
//       {
//         ignorePackages: true,
//         checkTypeImports: true,
//       },
//     ],
//     "no-nodejs-modules": "allow",
//     "jsx-no-new-function-as-prop": "allow",
//   },
//   options: {
//     typeAware: true,
//     typeCheck: true,
//   },
// },
