import { Predicate } from 'effect'

export const isSafeReturnTo = (value: string | undefined): value is string =>
  Predicate.isNotNullish(value) && value.startsWith('/') && !value.startsWith('//')

export const withReturnTo = (basePath: string, returnTo: string | undefined): string =>
  isSafeReturnTo(returnTo) ? `${basePath}?return_to=${encodeURIComponent(returnTo)}` : basePath
