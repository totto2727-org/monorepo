import { Predicate } from 'effect'

export const isSafeReturnTo = (value: string | undefined): boolean =>
  Predicate.isNotNullish(value) && value.startsWith('/') && !value.startsWith('//')

export const getSafeReturnTo = (value: string | undefined): string | undefined =>
  Predicate.isNotNullish(value) && isSafeReturnTo(value) ? value : undefined

export const withReturnTo = (basePath: string, returnTo: string | undefined): string => {
  const safeReturnTo = getSafeReturnTo(returnTo)
  return Predicate.isNotNullish(safeReturnTo) ? `${basePath}?return_to=${encodeURIComponent(safeReturnTo)}` : basePath
}
