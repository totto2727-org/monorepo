/**
 * Extracts a cookie value by name from a `Cookie` header string and returns it
 * as an `Authorization: Bearer <token>` value, or `null` if absent.
 */
// oxlint-disable rules/force-predicate rules/force-string-empty -- zero-runtime-deps
export const extractBearerFromCookie = (cookieName: string, cookieHeader: string | undefined): string | null => {
  // oxlint-disable-next-line rules/force-predicate -- no Predicate in zero-runtime-deps
  if (cookieHeader === undefined) {
    return null
  }
  for (const part of cookieHeader.split(';')) {
    const [rawKey, ...valueParts] = part.split('=')
    if (rawKey === undefined) {
      continue
    }
    const key = rawKey.trim()
    if (key === cookieName) {
      const value = valueParts.join('=').trim()
      return value !== '' ? `Bearer ${value}` : null
    }
  }
  return null
}
