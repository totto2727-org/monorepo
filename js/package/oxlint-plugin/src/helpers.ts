import { Predicate } from 'effect'

export const hasProperty = <K extends PropertyKey>(obj: unknown, key: K): obj is Record<K, unknown> =>
  Predicate.isObjectKeyword(obj) && key in obj

export const isReportable = (u: unknown): u is Record<string, unknown> & { range: [number, number] } =>
  Predicate.isObject(u) && 'range' in u

export const isEqualityOperator = (op: unknown): op is '==' | '!=' | '===' | '!==' =>
  op === '==' || op === '!=' || op === '===' || op === '!=='

export const getLiteralNumber = (node: unknown): number | null => {
  if (Predicate.isObject(node) && node.type === 'Literal' && Predicate.isNumber(node.value)) {
    return node.value
  }
  return null
}

export const isSchemaMethodCall = (node: unknown, methodName: string): boolean => {
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

export const getImportSource = (node: unknown): string | null => {
  if (
    Predicate.isObject(node) &&
    hasProperty(node, 'source') &&
    Predicate.isObject(node.source) &&
    hasProperty(node.source, 'value') &&
    Predicate.isString(node.source.value)
  ) {
    return node.source.value
  }
  return null
}
