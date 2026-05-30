/** Shared tagged error payload shape for domain errors. */
export type TaggedErrorBaseType = { readonly message: string } | { readonly error: string; readonly message?: string }

/** Data.TaggedError-compatible payload shape for domain errors. */
export interface TaggedErrorBaseData {
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
