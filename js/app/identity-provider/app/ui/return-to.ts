import { Predicate, String } from 'effect'

export const getSafeReturnTo = (value: string | undefined): string | undefined => {
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

export const withReturnTo = (basePath: string, returnTo: string | undefined): string => {
  const safeReturnTo = getSafeReturnTo(returnTo)
  if (Predicate.isNullish(safeReturnTo)) {
    return basePath
  }
  return `${basePath}?return_to=${encodeURIComponent(safeReturnTo)}`
}
