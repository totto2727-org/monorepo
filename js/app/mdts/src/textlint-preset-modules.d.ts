declare module 'slopless' {
  import type { TextlintRuleModule, TextlintRuleOptions } from '@textlint/kernel'

  const preset: {
    readonly rules: Readonly<Record<string, TextlintRuleModule>>
    readonly rulesConfig: Readonly<Record<string, TextlintRuleOptions | boolean>>
  }

  export default preset
}

declare module 'textlint-rule-preset-ja-technical-writing' {
  import type { TextlintRuleModule, TextlintRuleOptions } from '@textlint/kernel'

  const preset: {
    readonly rules: Readonly<Record<string, TextlintRuleModule>>
    readonly rulesConfig: Readonly<Record<string, TextlintRuleOptions | boolean>>
  }

  export default preset
}
