export interface TaggedErrorBaseType {
  readonly message?: string
  readonly error?: unknown
}

export const errorMessageOrDefault = (error: unknown): string =>
  error instanceof Error ? error.toString() : (JSON.stringify(error) ?? '')
