import { Predicate } from 'effect'

export const errorMessageOrDefault = (error: unknown, defaultMessage = String(error)): string => {
  if (Predicate.isObject(error) && 'message' in error && Predicate.isString(error.message)) {
    return error.message
  }
  return defaultMessage
}
