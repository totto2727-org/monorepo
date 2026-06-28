import { Predicate } from 'effect'

export const getReturnToPath = (value: string | undefined): string => {
  if (Predicate.isNullish(value)) {
    return '/app'
  }

  try {
    const url = new URL(decodeURIComponent(value), 'https://example.com')
    return `${url.pathname}${url.search}`
  } catch {
    return '/app'
  }
}
