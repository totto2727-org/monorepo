import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { getImportSource, hasProperty, isReportable } from '../helpers.ts'

const HONO_FACTORY_SOURCE = 'hono/factory'
const CREATE_MIDDLEWARE_NAME = 'createMiddleware'
const MESSAGE =
  'Do not use raw `createMiddleware` from `hono/factory` in application code. Use the shared `factory.createMiddleware` instance instead. Shared library code may disable this rule with a reason.'

const getIdentifierName = (node: unknown): string | null =>
  Predicate.isObject(node) && hasProperty(node, 'name') && Predicate.isString(node.name) ? node.name : null

export const isCreateMiddlewareImportSpecifier = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'ImportSpecifier' &&
  hasProperty(node, 'imported') &&
  getIdentifierName(node.imported) === CREATE_MIDDLEWARE_NAME

export const isNamespaceCreateMiddlewareCall = (node: unknown, namespaceNames: ReadonlySet<string>): boolean => {
  if (!Predicate.isObject(node) || node.type !== 'CallExpression' || !hasProperty(node, 'callee')) {
    return false
  }
  const { callee } = node
  if (!Predicate.isObject(callee) || callee.type !== 'MemberExpression' || callee.computed === true) {
    return false
  }
  if (getIdentifierName(callee.property) !== CREATE_MIDDLEWARE_NAME) {
    return false
  }
  const objectName = getIdentifierName(callee.object)
  return !Predicate.isNullish(objectName) && namespaceNames.has(objectName)
}

const rule: Rule = {
  create(context: Context) {
    const honoFactoryNamespaceNames = new Set<string>()

    return {
      CallExpression(node: unknown) {
        if (!isReportable(node) || !isNamespaceCreateMiddlewareCall(node, honoFactoryNamespaceNames)) {
          return
        }
        context.report({ message: MESSAGE, node })
      },
      ImportDeclaration(node: unknown) {
        if (getImportSource(node) !== HONO_FACTORY_SOURCE || !isReportable(node)) {
          return
        }
        const specifiers = Predicate.isObject(node) && hasProperty(node, 'specifiers') ? node.specifiers : null
        if (!Array.isArray(specifiers)) {
          return
        }
        for (const specifier of specifiers) {
          if (!Predicate.isObject(specifier)) {
            continue
          }
          if (isCreateMiddlewareImportSpecifier(specifier)) {
            context.report({ message: MESSAGE, node })
            continue
          }
          if (specifier.type === 'ImportNamespaceSpecifier' && hasProperty(specifier, 'local')) {
            const localName = getIdentifierName(specifier.local)
            if (!Predicate.isNullish(localName)) {
              honoFactoryNamespaceNames.add(localName)
            }
          }
        }
      },
    }
  },
  meta: {
    type: 'problem',
  },
}

export default rule
