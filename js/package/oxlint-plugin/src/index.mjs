// @ts-nocheck

// ---------------------------------------------------------------------------
// force-ts-extension
// ---------------------------------------------------------------------------

const forceTsExtensionRule = {
  create(context) {
    const check = (node) => {
      if (!('source' in node) || !node.source) {
        return
      }
      const { source } = node
      const { raw, value } = source
      if (typeof value !== 'string' || typeof raw !== 'string') {
        return
      }

      const match = value.match(/^(\.*|#(?!#).*)(\/.*)\.js(x?)$/)
      if (!match) {
        return
      }

      const { 1: start, 2: path, 3: x } = match
      const fixed = `${start}${path}.ts${x}`
      const [quote] = raw

      context.report({
        fix(fixer) {
          return fixer.replaceText(source, `${quote}${fixed}${quote}`)
        },
        message: `Use .ts${x} extension instead of .js${x}`,
        node: source,
      })
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

const typeofToPredicateMap = {
  bigint: 'Predicate.isBigInt',
  boolean: 'Predicate.isBoolean',
  function: 'Predicate.isFunction',
  number: 'Predicate.isNumber',
  object: 'Predicate.isObject',
  string: 'Predicate.isString',
  symbol: 'Predicate.isSymbol',
  undefined: 'Predicate.isUndefined',
}

const isNullLiteral = (node) => node.type === 'Literal' && node.value === null

const isUndefinedIdentifier = (node) => node.type === 'Identifier' && node.name === 'undefined'

const getNullishSide = (node) => {
  if (isNullLiteral(node)) {
    return 'null'
  }
  if (isUndefinedIdentifier(node)) {
    return 'undefined'
  }
  return null
}

const getTypeofType = (node) => {
  if (node.type === 'UnaryExpression' && node.operator === 'typeof') {
    return 'typeof'
  }
  return null
}

const getStringValue = (node) => {
  if (node.type === 'Literal' && typeof node.value === 'string') {
    return node.value
  }
  return null
}

const forcePredicateRule = {
  create(context) {
    return {
      BinaryExpression(node) {
        if (node.operator !== '==' && node.operator !== '!=' && node.operator !== '===' && node.operator !== '!==') {
          return
        }

        const leftKind = getNullishSide(node.left)
        const rightKind = getNullishSide(node.right)
        const kind = leftKind ?? rightKind

        if (kind) {
          const predicateFn = kind === 'null' ? 'Predicate.isNull' : 'Predicate.isUndefined'
          context.report({
            message: `Use ${predicateFn}() instead of direct ${kind} comparison`,
            node,
          })
          return
        }

        const leftTypeof = getTypeofType(node.left)
        const rightTypeof = getTypeofType(node.right)
        const leftStr = getStringValue(node.left)
        const rightStr = getStringValue(node.right)

        let typeStr = null
        if (leftTypeof) {
          typeStr = rightStr
        } else if (rightTypeof) {
          typeStr = leftStr
        }
        if (!typeStr) {
          return
        }

        const predicateFn = typeofToPredicateMap[typeStr]
        if (!predicateFn) {
          return
        }

        context.report({
          message: `Use ${predicateFn}() instead of typeof comparison`,
          node,
        })
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

const noLetRule = {
  create(context) {
    return {
      VariableDeclaration(node) {
        if (node.kind !== 'let') {
          return
        }
        context.report({
          message: 'Use const with shadowing instead of let. Reassignment via let is prohibited.',
          node,
        })
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

const tagToPredicateMap = {
  None: 'Option.isNone',
  Some: 'Option.isSome',
}

const getOptionTag = (node) => {
  if (node.type === 'Literal' && typeof node.value === 'string' && node.value in tagToPredicateMap) {
    return node.value
  }
  return null
}

const isTagPropertyAccess = (node) =>
  node.type === 'MemberExpression' &&
  !node.computed &&
  node.property.type === 'Identifier' &&
  node.property.name === '_tag'

const isTypeofTag = (node) =>
  node.type === 'UnaryExpression' && node.operator === 'typeof' && isTagPropertyAccess(node.argument)

const noOptionTagComparisonRule = {
  create(context) {
    return {
      BinaryExpression(node) {
        if (node.operator !== '==' && node.operator !== '!=' && node.operator !== '===' && node.operator !== '!==') {
          return
        }

        const leftTag = getOptionTag(node.left)
        const rightTag = getOptionTag(node.right)
        const tag = leftTag ?? rightTag

        if (!tag) {
          return
        }

        const otherSide = leftTag ? node.right : node.left
        if (!isTagPropertyAccess(otherSide) && !isTypeofTag(otherSide)) {
          return
        }

        const predicateFn = tagToPredicateMap[tag]
        const isEquality = node.operator === '==' || node.operator === '==='

        const tagExpr = otherSide

        context.report({
          fix(fixer) {
            const source = context.sourceCode.getText(tagExpr.object)
            const prefix = isEquality ? '' : '!'
            return fixer.replaceText(node, `${prefix}${predicateFn}(${source})`)
          },
          message: `Use ${predicateFn}() instead of _tag === '${tag}'`,
          node,
        })
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
    'no-let': noLetRule,
    'no-option-tag-comparison': noOptionTagComparisonRule,
  },
}

export default plugin
