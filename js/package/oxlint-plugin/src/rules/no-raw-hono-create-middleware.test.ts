import { describe, expect, test } from 'vite-plus/test'

import { runRuleTest } from '../__fixtures__/run-rule-test.ts'
import rule, {
  isCreateMiddlewareImportSpecifier,
  isNamespaceCreateMiddlewareCall,
} from './no-raw-hono-create-middleware.ts'

describe('isCreateMiddlewareImportSpecifier', () => {
  test('createMiddleware import specifier returns true', () => {
    expect(
      isCreateMiddlewareImportSpecifier({
        imported: { name: 'createMiddleware', type: 'Identifier' },
        type: 'ImportSpecifier',
      }),
    ).toBe(true)
  })

  test('createFactory import specifier returns false', () => {
    expect(
      isCreateMiddlewareImportSpecifier({
        imported: { name: 'createFactory', type: 'Identifier' },
        type: 'ImportSpecifier',
      }),
    ).toBe(false)
  })
})

describe('isNamespaceCreateMiddlewareCall', () => {
  test('namespace createMiddleware call returns true', () => {
    expect(
      isNamespaceCreateMiddlewareCall(
        {
          callee: {
            computed: false,
            object: { name: 'HonoFactory', type: 'Identifier' },
            property: { name: 'createMiddleware', type: 'Identifier' },
            type: 'MemberExpression',
          },
          type: 'CallExpression',
        },
        new Set(['HonoFactory']),
      ),
    ).toBe(true)
  })

  test('shared factory.createMiddleware call returns false', () => {
    expect(
      isNamespaceCreateMiddlewareCall(
        {
          callee: {
            computed: false,
            object: { name: 'factory', type: 'Identifier' },
            property: { name: 'createMiddleware', type: 'Identifier' },
            type: 'MemberExpression',
          },
          type: 'CallExpression',
        },
        new Set(['HonoFactory']),
      ),
    ).toBe(false)
  })
})

runRuleTest('no-raw-hono-create-middleware', rule, {
  invalid: [
    {
      code: "import { createMiddleware } from 'hono/factory'\nexport const middleware = createMiddleware((c, next) => next())",
      errors: 1,
      name: 'direct createMiddleware import is reported',
    },
    {
      code: "import { createMiddleware as cm } from 'hono/factory'\nexport const middleware = cm((c, next) => next())",
      errors: 1,
      name: 'aliased createMiddleware import is reported',
    },
    {
      code: "import * as HonoFactory from 'hono/factory'\nexport const middleware = HonoFactory.createMiddleware((c, next) => next())",
      errors: 1,
      name: 'namespace createMiddleware call is reported',
    },
  ],
  valid: [
    {
      code: "import { createFactory } from 'hono/factory'\nexport const factory = createFactory()",
      name: 'createFactory is allowed for shared factory modules',
    },
    {
      code: "import { factory } from '#@/feature/share/lib/hono/factory.ts'\nexport const middleware = factory.createMiddleware((c, next) => next())",
      name: 'shared factory createMiddleware is allowed',
    },
    {
      code: "import * as Other from './factory.ts'\nexport const middleware = Other.createMiddleware((c, next) => next())",
      name: 'namespace createMiddleware from non-hono source is allowed',
    },
  ],
})
