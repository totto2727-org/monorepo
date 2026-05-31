import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { hasProperty, isReportable } from '../helpers.ts'

const TOP_LEVEL_DECODER_MESSAGE =
  'Hoist schema decoder construction to module top level and call the cached function inside this scope. Building the decoder per call re-runs the schema compilation on every invocation.'

const matchMemberCallByPrefix = (node: unknown, namespace: string, prefix: string): boolean => {
  if (
    !Predicate.isObject(node) ||
    node.type !== 'CallExpression' ||
    !Predicate.isObject(node.callee) ||
    node.callee.type !== 'MemberExpression' ||
    Predicate.isTruthy(node.callee.computed)
  ) {
    return false
  }
  const { object, property } = node.callee
  if (
    !Predicate.isObject(object) ||
    object.type !== 'Identifier' ||
    !hasProperty(object, 'name') ||
    object.name !== namespace
  ) {
    return false
  }
  if (
    !Predicate.isObject(property) ||
    property.type !== 'Identifier' ||
    !hasProperty(property, 'name') ||
    !Predicate.isString(property.name)
  ) {
    return false
  }
  return property.name.startsWith(prefix)
}

export const isHoistableDecoderCall = (node: unknown): boolean =>
  matchMemberCallByPrefix(node, 'Schema', 'decode') || matchMemberCallByPrefix(node, 'HttpClientResponse', 'schema')

const rule: Rule = {
  create(context: Context) {
    const functionStack: true[] = []
    const enterFunction = () => {
      functionStack.push(true)
    }
    const exitFunction = () => {
      functionStack.pop()
    }
    return {
      ArrowFunctionExpression: enterFunction,
      'ArrowFunctionExpression:exit': exitFunction,
      CallExpression(node: unknown) {
        if (Predicate.isNullish(functionStack[0]) || !isReportable(node)) {
          return
        }
        if (isHoistableDecoderCall(node)) {
          context.report({
            message: TOP_LEVEL_DECODER_MESSAGE,
            node,
          })
        }
      },
      FunctionDeclaration: enterFunction,
      'FunctionDeclaration:exit': exitFunction,
      FunctionExpression: enterFunction,
      'FunctionExpression:exit': exitFunction,
    }
  },
  meta: {
    type: 'problem',
  },
}

export default rule
