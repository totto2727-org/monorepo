// oxlint-disable typescript/no-unsafe-type-assertion
import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

const isNotNull = <A>(value: A): value is A & Record<string, unknown> => Predicate.isNotNull(value)

const hasProperty = <K extends PropertyKey>(obj: unknown, key: K): obj is Record<K, unknown> =>
  Predicate.isObjectKeyword(obj) && key in obj

// ---------------------------------------------------------------------------
// force-ts-extension
// ---------------------------------------------------------------------------

const forceTsExtensionRule: Rule = {
  create(context: Context) {
    const check = (node: unknown): void => {
      if (Predicate.isObject(node) && hasProperty(node, 'source') && Predicate.isNotNull(node.source)) {
        const { source } = node
        const { raw, value } = source as Record<string, unknown>
        if (Predicate.isString(value) && Predicate.isString(raw)) {
          const match = value.match(/^(\.*|#(?!#).*)(\/.*)\.js(x?)$/)
          if (Predicate.isNotNull(match)) {
            const [, start, path, x] = match
            const fixed = `${start}${path}.ts${x ?? ''}`
            const [quote] = raw

            context.report({
              fix(fixer) {
                return fixer.replaceText(source as never, `${quote}${fixed}${quote}`)
              },
              message: `Use .ts${x ?? ''} extension instead of .js${x ?? ''}`,
              node: source as never,
            })
          }
        }
      }
    }

    return {
      ExportAllDeclaration: check,
      ExportNamedDeclaration: check,
      ImportDeclaration: check,
    }
  },
  meta: {
    fixable: 'code',
    type: 'problem',
  },
}

// ---------------------------------------------------------------------------
// force-predicate
// ---------------------------------------------------------------------------

const typeofToPredicateMap: Record<string, string> = {
  bigint: 'Predicate.isBigInt',
  boolean: 'Predicate.isBoolean',
  function: 'Predicate.isFunction',
  number: 'Predicate.isNumber',
  object: 'Predicate.isObject',
  string: 'Predicate.isString',
  symbol: 'Predicate.isSymbol',
  undefined: 'Predicate.isUndefined',
}

const isNullLiteral = (node: unknown): boolean =>
  Predicate.isObject(node) && node.type === 'Literal' && Predicate.isNullish(node.value)

const isUndefinedIdentifier = (node: unknown): boolean =>
  Predicate.isObject(node) && node.type === 'Identifier' && node.name === 'undefined'

const getNullishSide = (node: unknown): 'null' | 'undefined' | null => {
  if (isNullLiteral(node)) {
    return 'null'
  }
  if (isUndefinedIdentifier(node)) {
    return 'undefined'
  }
  return null
}

const getTypeofType = (node: unknown): 'typeof' | null => {
  if (Predicate.isObject(node) && node.type === 'UnaryExpression' && node.operator === 'typeof') {
    return 'typeof'
  }
  return null
}

const getStringValue = (node: unknown): string | null => {
  if (Predicate.isObject(node) && node.type === 'Literal' && Predicate.isString(node.value)) {
    return node.value
  }
  return null
}

const isEqualityOperator = (op: unknown): op is '==' | '!=' | '===' | '!==' =>
  op === '==' || op === '!=' || op === '===' || op === '!=='

const resolveTypeStr = (
  leftTypeof: 'typeof' | null,
  rightTypeof: 'typeof' | null,
  leftStr: string | null,
  rightStr: string | null,
): string | null => {
  if (Predicate.isNotNull(leftTypeof)) {
    return rightStr
  }
  if (Predicate.isNotNull(rightTypeof)) {
    return leftStr
  }
  return null
}

const forcePredicateRule: Rule = {
  create(context: Context) {
    return {
      BinaryExpression(node: unknown) {
        if (Predicate.isObject(node) && isEqualityOperator(node.operator)) {
          const leftKind = getNullishSide(node.left)
          const rightKind = getNullishSide(node.right)
          const kind = leftKind ?? rightKind

          if (Predicate.isNotNull(kind)) {
            const predicateFn = kind === 'null' ? 'Predicate.isNull' : 'Predicate.isUndefined'
            context.report({
              message: `Use ${predicateFn}() instead of direct ${kind} comparison`,
              node: node as never,
            })
            return
          }

          const leftTypeof = getTypeofType(node.left)
          const rightTypeof = getTypeofType(node.right)
          const leftStr = getStringValue(node.left)
          const rightStr = getStringValue(node.right)

          const typeStr = resolveTypeStr(leftTypeof, rightTypeof, leftStr, rightStr)

          if (Predicate.isNullish(typeStr)) {
            return
          }

          const predicateFn = typeofToPredicateMap[typeStr]
          if (Predicate.isNullish(predicateFn)) {
            return
          }

          context.report({
            message: `Use ${predicateFn}() instead of typeof comparison`,
            node: node as never,
          })
        }
      },
    }
  },
  meta: {
    type: 'problem',
  },
}

// ---------------------------------------------------------------------------
// no-let
// ---------------------------------------------------------------------------

const noLetRule: Rule = {
  create(context: Context) {
    return {
      VariableDeclaration(node: unknown) {
        if (Predicate.isObject(node) && node.kind === 'let') {
          context.report({
            message: 'Use const with shadowing instead of let. Reassignment via let is prohibited.',
            node: node as never,
          })
        }
      },
    }
  },
  meta: {
    type: 'problem',
  },
}

// ---------------------------------------------------------------------------
// no-option-tag-comparison
// ---------------------------------------------------------------------------

const tagToPredicateMap: Record<string, string> = {
  None: 'Option.isNone',
  Some: 'Option.isSome',
}

const getOptionTag = (node: unknown): string | null => {
  if (Predicate.isObject(node) && node.type === 'Literal' && Predicate.isString(node.value)) {
    const { value } = node
    if (value in tagToPredicateMap) {
      return value
    }
  }
  return null
}

const isTagPropertyAccess = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'MemberExpression' &&
  node.computed !== true &&
  Predicate.isObject(node.property) &&
  node.property.type === 'Identifier' &&
  node.property.name === '_tag'

const isTypeofTag = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'UnaryExpression' &&
  node.operator === 'typeof' &&
  isTagPropertyAccess(node.argument)

const noOptionTagComparisonRule: Rule = {
  create(context: Context) {
    return {
      BinaryExpression(node: unknown) {
        if (Predicate.isObject(node) && isEqualityOperator(node.operator)) {
          const leftTag = getOptionTag(node.left)
          const rightTag = getOptionTag(node.right)
          const tag = leftTag ?? rightTag

          if (Predicate.isNullish(tag)) {
            return
          }

          const otherSide = isNotNull(leftTag) ? node.right : node.left
          if (isTagPropertyAccess(otherSide) || isTypeofTag(otherSide)) {
            const predicateFn = tagToPredicateMap[tag]
            const isEquality = node.operator === '==' || node.operator === '==='

            context.report({
              fix(fixer) {
                const source = context.sourceCode.getText(
                  (hasProperty(otherSide, 'object') ? otherSide.object : otherSide) as never,
                )
                const prefix = isEquality ? '' : '!'
                return fixer.replaceText(node as never, `${prefix}${predicateFn}(${source})`)
              },
              message: `Use ${predicateFn}() instead of _tag === '${tag}'`,
              node: node as never,
            })
          }
        }
      },
    }
  },
  meta: {
    fixable: 'code',
    type: 'problem',
  },
}

// ---------------------------------------------------------------------------
// no-sync-decode
// ---------------------------------------------------------------------------

const BANNED_DECODE_METHODS: Record<string, string> = {
  decodePromise: 'decodeEffect',
  decodeSync: 'decodeEffect',
  decodeUnknownPromise: 'decodeUnknownEffect',
  decodeUnknownSync: 'decodeUnknownEffect',
}

const isSchemaMethodCall = (node: unknown, methodName: string): boolean => {
  if (
    Predicate.isObject(node) &&
    node.type === 'CallExpression' &&
    Predicate.isObject(node.callee) &&
    node.callee.type === 'MemberExpression' &&
    !Predicate.isTruthy(node.callee.computed) &&
    Predicate.isObject(node.callee.object) &&
    node.callee.object.type === 'Identifier' &&
    node.callee.object.name === 'Schema' &&
    Predicate.isObject(node.callee.property) &&
    node.callee.property.type === 'Identifier' &&
    node.callee.property.name === methodName
  ) {
    return true
  }
  return false
}

const isSchemaBannedDecodeCall = (node: unknown): string | null => {
  for (const method of Object.keys(BANNED_DECODE_METHODS)) {
    if (isSchemaMethodCall(node, method)) {
      return method
    }
  }
  return null
}

const noSyncDecodeRule: Rule = {
  create(context: Context) {
    return {
      CallExpression(node: unknown) {
        const method = isSchemaBannedDecodeCall(node)
        if (Predicate.isNotNull(method)) {
          const recommended = BANNED_DECODE_METHODS[method]
          context.report({
            message: `Use Schema.${recommended} or Schema.decodeExit instead of Schema.${method}.`,
            node: node as never,
          })
        }
      },
    }
  },
  meta: {
    type: 'problem',
  },
}

// ---------------------------------------------------------------------------
// prefer-non-unknown-decode
// ---------------------------------------------------------------------------

const UNKNOWN_DECODE_METHODS: Record<string, string> = {
  decodeUnknownEffect: 'decodeEffect',
  decodeUnknownExit: 'decodeExit',
}

const isSchemaUnknownDecodeCall = (node: unknown): string | null => {
  for (const method of Object.keys(UNKNOWN_DECODE_METHODS)) {
    if (isSchemaMethodCall(node, method)) {
      return method
    }
  }
  return null
}

const preferNonUnknownDecodeRule: Rule = {
  create(context: Context) {
    return {
      CallExpression(node: unknown) {
        const method = isSchemaUnknownDecodeCall(node)
        if (Predicate.isNotNull(method)) {
          const recommended = UNKNOWN_DECODE_METHODS[method]
          context.report({
            message: `Prefer Schema.${recommended} over Schema.${method}. Use unknown variants only when input type is truly unknown. Add an oxlint-disable comment if the unknown variant is required.`,
            node: node as never,
          })
        }
      },
    }
  },
  meta: {
    type: 'suggestion',
  },
}

// ---------------------------------------------------------------------------
// prefer-is-nullish
// ---------------------------------------------------------------------------

const isPredicateCall = (node: unknown, methodName: string): boolean =>
  Predicate.isObject(node) &&
  node.type === 'CallExpression' &&
  Predicate.isObject(node.callee) &&
  node.callee.type === 'MemberExpression' &&
  Predicate.isObject(node.callee.object) &&
  node.callee.object.type === 'Identifier' &&
  node.callee.object.name === 'Predicate' &&
  Predicate.isObject(node.callee.property) &&
  node.callee.property.type === 'Identifier' &&
  node.callee.property.name === methodName

const preferIsNullishRule: Rule = {
  create(context: Context) {
    return {
      CallExpression(node: unknown) {
        const isNull = isPredicateCall(node, 'isNull')
        const isUndefined = isPredicateCall(node, 'isUndefined')
        if (isNull || isUndefined) {
          const method = isNull ? 'isNull' : 'isUndefined'
          context.report({
            message: `Prefer Predicate.isNullish over Predicate.${method}. Use null/undefined distinction only when necessary and disable this rule with an oxlint-disable comment.`,
            node: node as never,
          })
        }
      },
    }
  },
  meta: {
    type: 'suggestion',
  },
}

// ---------------------------------------------------------------------------
// no-eslint-disable-comments
// ---------------------------------------------------------------------------

const ESLINT_DISABLE_RE = /^\s*eslint-disable(?:-next-line|-line)?\b/gm

const noEslintDisableRule: Rule = {
  create(context: Context) {
    return {
      'Program:exit'() {
        const comments = context.sourceCode.getAllComments()
        for (const comment of comments) {
          const { value } = comment
          if (ESLINT_DISABLE_RE.test(value)) {
            //
            const fixed = value.replaceAll('eslint-disable', 'oxlint-disable')
            context.report({
              fix(fixer) {
                const [start, end] = comment.range
                const prefix = comment.type === 'Block' ? '/*' : '//'
                const suffix = comment.type === 'Block' ? '*/' : ''
                return fixer.replaceTextRange([start, end], `${prefix}${fixed}${suffix}`)
              },
              message: 'Use oxlint-disable instead of eslint-disable.',
              node: comment as never,
            })
          }
        }
      },
    }
  },
  meta: {
    fixable: 'code',
    type: 'problem',
  },
}

// ---------------------------------------------------------------------------
// Plugin
// ---------------------------------------------------------------------------

const plugin = {
  meta: { name: 'rules' },
  rules: {
    'force-predicate': forcePredicateRule,
    'force-ts-extension': forceTsExtensionRule,
    'no-eslint-disable-comments': noEslintDisableRule,
    'no-let': noLetRule,
    'no-option-tag-comparison': noOptionTagComparisonRule,
    'no-sync-decode': noSyncDecodeRule,
    'prefer-is-nullish': preferIsNullishRule,
    'prefer-non-unknown-decode': preferNonUnknownDecodeRule,
  },
}

export default plugin
