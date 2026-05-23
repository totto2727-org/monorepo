import { Predicate, String } from 'effect'

/**
 * Extracts a cookie value by name from a `Cookie` header string and returns it
 * as an `Authorization: Bearer <token>` value, or `null` if absent.
 */
export const extractBearerFromCookie = (cookieName: string, cookieHeader: string | undefined): string | null => {
  if (Predicate.isNullish(cookieHeader)) {
    return null
  }

  for (const part of cookieHeader.split(';')) {
    const [rawKey, ...valueParts] = part.split('=')
    if (Predicate.isNullish(rawKey)) {
      continue
    }

    if (rawKey.trim() === cookieName) {
      const value = valueParts.join('=').trim()
      return String.isEmpty(value) ? null : `Bearer ${value}`
    }
  }

  return null
}
