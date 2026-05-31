import { Undefinable } from '@totto2727/fp/option-t'

export const isSafeReturnTo = (value: string): boolean => value.startsWith('/') && !value.startsWith('//')

export const getSafeReturnTo = (value: string | undefined): string | undefined =>
  Undefinable.andThen(value, (returnTo) => (isSafeReturnTo(returnTo) ? returnTo : undefined))

export const withReturnTo = (basePath: string, returnTo: string | undefined): string => {
  const safeReturnTo = getSafeReturnTo(returnTo)
  return Undefinable.mapOr(safeReturnTo, basePath, (value) => `${basePath}?return_to=${encodeURIComponent(value)}`)
}
