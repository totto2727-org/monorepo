import { Predicate, String } from 'effect'

export const getReturnToPath = (value: string | undefined): string | undefined => {
  if (Predicate.isNullish(value) || String.isEmpty(value)) {
    return undefined
  }
  try {
    const url = new URL(decodeURIComponent(value), 'https://example.com')
    return `${url.pathname}${url.search}`
  } catch {
    return undefined
  }
}
