/** Data.TaggedError-compatible payload shape for domain errors. */
export interface TaggedErrorBaseType {
  /** Raw caught error value. */
  readonly error?: unknown
  /** Message for errors created at the current domain boundary. */
  readonly message?: string
}

declare global {
  interface ErrorOptions {
    readonly error?: unknown
  }
}
