import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { hasProperty, isReportable } from '../helpers.ts'

const REDUNDANT_TYPE_ALIAS_MESSAGE =
  'Avoid type aliases that merely rename another type (e.g. `type SentEmail = SendParams`). Inline the original, or keep the alias only inside an anti-corruption layer with a documented disable reason.'
const REDUNDANT_VALUE_ALIAS_MESSAGE =
  'Avoid exported bindings that merely rename another value (e.g. `export const sentEmail = sendParams`). Re-export the original directly, or keep the alias only inside an anti-corruption layer with a documented disable reason.'

const hasTypeArguments = (node: unknown): boolean =>
  Predicate.isObject(node) && hasProperty(node, 'typeArguments') && Predicate.isNotNullish(node.typeArguments)

const hasGenericTypeParameters = (node: unknown): boolean =>
  Predicate.isObject(node) && hasProperty(node, 'typeParameters') && Predicate.isNotNullish(node.typeParameters)

const isPlainTypeReference = (node: unknown): boolean =>
  Predicate.isObject(node) && node.type === 'TSTypeReference' && !hasTypeArguments(node)

export const isRedundantTypeAlias = (node: unknown): boolean => {
  if (!Predicate.isObject(node) || node.type !== 'TSTypeAliasDeclaration') {
    return false
  }
  if (hasGenericTypeParameters(node)) {
    return false
  }
  return hasProperty(node, 'typeAnnotation') && isPlainTypeReference(node.typeAnnotation)
}

export const isIdentifierInitDeclarator = (declarator: unknown): boolean =>
  Predicate.isObject(declarator) &&
  hasProperty(declarator, 'id') &&
  Predicate.isObject(declarator.id) &&
  declarator.id.type === 'Identifier' &&
  hasProperty(declarator, 'init') &&
  Predicate.isObject(declarator.init) &&
  declarator.init.type === 'Identifier'

const rule: Rule = {
  create(context: Context) {
    return {
      ExportNamedDeclaration(node: unknown) {
        if (!isReportable(node) || !Predicate.isObject(node) || !hasProperty(node, 'declaration')) {
          return
        }
        const { declaration } = node
        if (
          !Predicate.isObject(declaration) ||
          declaration.type !== 'VariableDeclaration' ||
          !hasProperty(declaration, 'declarations') ||
          !Array.isArray(declaration.declarations)
        ) {
          return
        }
        for (const declarator of declaration.declarations) {
          if (isIdentifierInitDeclarator(declarator) && isReportable(declarator)) {
            context.report({
              message: REDUNDANT_VALUE_ALIAS_MESSAGE,
              node: declarator,
            })
          }
        }
      },
      TSTypeAliasDeclaration(node: unknown) {
        if (!isReportable(node)) {
          return
        }
        if (isRedundantTypeAlias(node)) {
          context.report({
            message: REDUNDANT_TYPE_ALIAS_MESSAGE,
            node,
          })
        }
      },
    }
  },
  meta: {
    type: 'problem',
  },
}

export default rule
