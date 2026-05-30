import { Predicate } from 'effect'

export const errorMessageOrDefault = (error: unknown, defaultMessage = String(error)): string => {
  if (Predicate.isObject(error) && 'message' in error && Predicate.isString(error.message)) {
    return error.message
  }
  return defaultMessage
}

export const errorNameOrDefault = (error: unknown, defaultName = 'Error'): string => {
  if (Predicate.isObject(error) && 'name' in error && Predicate.isString(error.name)) {
    return error.name
  }
  return defaultName
}

export const errorCauseOrUndefined = (error: unknown): unknown =>
  Predicate.isObject(error) && 'cause' in error ? error.cause : undefined
