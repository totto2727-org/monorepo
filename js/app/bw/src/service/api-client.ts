import { Data, Effect, Schema } from 'effect'
import type { HttpClientResponse } from 'effect/unstable/http'
import { HttpBody, HttpClient } from 'effect/unstable/http'

import type { CrawlStatusResult, SnapshotResult } from '#@/schema/response.ts'
import { CrawlStartApiResponse, CrawlStatusApiResponse, SnapshotApiResponse } from '#@/schema/response.ts'
import type { AuthConfig } from '#@/service/auth.ts'

const BASE_PATH = '/client/v4/accounts'

export class ApiError extends Data.TaggedError('ApiError')<{
  readonly endpoint: string
  readonly status: number
  readonly message: string
}> {}

const buildUrl = (auth: AuthConfig, endpoint: string): string =>
  `https://api.cloudflare.com${BASE_PATH}/${auth.accountId}/browser-rendering${endpoint}`

const postRequest = (
  auth: AuthConfig,
  endpoint: string,
  body: Record<string, unknown>,
): Effect.Effect<HttpClientResponse.HttpClientResponse, ApiError, HttpClient.HttpClient> =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient
    const response = yield* client
      .post(buildUrl(auth, endpoint), {
        body: HttpBody.jsonUnsafe(body),
        headers: { Authorization: `Bearer ${auth.apiToken}` },
      })
      .pipe(
        Effect.mapError(
          (error) =>
            new ApiError({
              endpoint,
              message: error instanceof Error ? error.message : JSON.stringify(error),
              status: 0,
            }),
        ),
      )
    if (response.status >= 400) {
      const text = yield* response.text.pipe(Effect.orElseSucceed(() => ''))
      return yield* new ApiError({ endpoint, message: text, status: response.status })
    }
    return response
  })

const getRequest = (
  auth: AuthConfig,
  endpoint: string,
  params?: Record<string, string>,
): Effect.Effect<HttpClientResponse.HttpClientResponse, ApiError, HttpClient.HttpClient> =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient
    const url = new URL(buildUrl(auth, endpoint))
    if (params) {
      for (const [key, value] of Object.entries(params)) {
        url.searchParams.set(key, value)
      }
    }
    const response = yield* client
      .get(url.toString(), {
        headers: { Authorization: `Bearer ${auth.apiToken}` },
      })
      .pipe(
        Effect.mapError(
          (error) =>
            new ApiError({
              endpoint,
              message: error instanceof Error ? error.message : JSON.stringify(error),
              status: 0,
            }),
        ),
      )
    if (response.status >= 400) {
      const text = yield* response.text.pipe(Effect.orElseSucceed(() => ''))
      return yield* new ApiError({ endpoint, message: text, status: response.status })
    }
    return response
  })

const postText = (
  auth: AuthConfig,
  endpoint: string,
  body: Record<string, unknown>,
): Effect.Effect<string, ApiError, HttpClient.HttpClient> =>
  Effect.gen(function* () {
    const response = yield* postRequest(auth, endpoint, body)
    const text: string = yield* response.text.pipe(
      Effect.mapError(
        (error) =>
          new ApiError({
            endpoint,
            message: error instanceof Error ? error.message : JSON.stringify(error),
            status: 0,
          }),
      ),
    )
    return text
  })

const postJson = (
  auth: AuthConfig,
  endpoint: string,
  body: Record<string, unknown>,
): Effect.Effect<unknown, ApiError, HttpClient.HttpClient> =>
  Effect.gen(function* () {
    const text = yield* postText(auth, endpoint, body)
    const parsed: unknown = JSON.parse(text)
    return parsed
  })

const postBinary = (
  auth: AuthConfig,
  endpoint: string,
  body: Record<string, unknown>,
): Effect.Effect<Uint8Array, ApiError, HttpClient.HttpClient> =>
  Effect.gen(function* () {
    const response = yield* postRequest(auth, endpoint, body)
    const buf: ArrayBuffer = yield* response.arrayBuffer.pipe(
      Effect.mapError(
        (error) =>
          new ApiError({
            endpoint,
            message: error instanceof Error ? error.message : JSON.stringify(error),
            status: 0,
          }),
      ),
    )
    return new Uint8Array(buf)
  })

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- input is unknown (API response JSON)
const decodeSnapshot = Schema.decodeUnknownEffect(SnapshotApiResponse)
// oxlint-disable-next-line rules/prefer-non-unknown-decode -- input is unknown (API response JSON)
const decodeCrawlStart = Schema.decodeUnknownEffect(CrawlStartApiResponse)
// oxlint-disable-next-line rules/prefer-non-unknown-decode -- input is unknown (API response JSON)
const decodeCrawlStatus = Schema.decodeUnknownEffect(CrawlStatusApiResponse)

export const content = (
  auth: AuthConfig,
  body: Record<string, unknown>,
): Effect.Effect<string, ApiError, HttpClient.HttpClient> => postText(auth, '/content', body)

export const screenshot = (
  auth: AuthConfig,
  body: Record<string, unknown>,
): Effect.Effect<Uint8Array, ApiError, HttpClient.HttpClient> => postBinary(auth, '/screenshot', body)

export const pdf = (
  auth: AuthConfig,
  body: Record<string, unknown>,
): Effect.Effect<Uint8Array, ApiError, HttpClient.HttpClient> => postBinary(auth, '/pdf', body)

export const markdown = (
  auth: AuthConfig,
  body: Record<string, unknown>,
): Effect.Effect<string, ApiError, HttpClient.HttpClient> => postText(auth, '/markdown', body)

export const snapshot = (
  auth: AuthConfig,
  body: Record<string, unknown>,
): Effect.Effect<SnapshotResult, ApiError, HttpClient.HttpClient> =>
  Effect.gen(function* () {
    const data = yield* postJson(auth, '/snapshot', body)
    const decoded = yield* decodeSnapshot(data).pipe(
      Effect.mapError(
        (e) =>
          new ApiError({
            endpoint: '/snapshot',
            message: e instanceof Error ? e.message : JSON.stringify(e),
            status: 0,
          }),
      ),
    )
    return decoded.result
  })

export const scrape = (
  auth: AuthConfig,
  body: Record<string, unknown>,
): Effect.Effect<unknown, ApiError, HttpClient.HttpClient> => postJson(auth, '/scrape', body)

export const jsonExtract = (
  auth: AuthConfig,
  body: Record<string, unknown>,
): Effect.Effect<unknown, ApiError, HttpClient.HttpClient> => postJson(auth, '/json', body)

export const links = (
  auth: AuthConfig,
  body: Record<string, unknown>,
): Effect.Effect<unknown, ApiError, HttpClient.HttpClient> => postJson(auth, '/links', body)

export const crawlStart = (
  auth: AuthConfig,
  body: Record<string, unknown>,
): Effect.Effect<string, ApiError, HttpClient.HttpClient> =>
  Effect.gen(function* () {
    const data = yield* postJson(auth, '/crawl', body)
    const parsed = yield* decodeCrawlStart(data).pipe(
      Effect.mapError(
        (e) =>
          new ApiError({ endpoint: '/crawl', message: e instanceof Error ? e.message : JSON.stringify(e), status: 0 }),
      ),
    )
    return parsed.result
  })

export const crawlStatus = (
  auth: AuthConfig,
  crawlId: string,
): Effect.Effect<CrawlStatusResult, ApiError, HttpClient.HttpClient> =>
  Effect.gen(function* () {
    const response = yield* getRequest(auth, `/crawl/${crawlId}`)
    const text: string = yield* response.text.pipe(
      Effect.mapError(
        (error) =>
          new ApiError({
            endpoint: `/crawl/${crawlId}`,
            message: error instanceof Error ? error.message : JSON.stringify(error),
            status: 0,
          }),
      ),
    )
    const parsed: unknown = JSON.parse(text)
    const decoded = yield* decodeCrawlStatus(parsed).pipe(
      Effect.mapError(
        (e) =>
          new ApiError({
            endpoint: `/crawl/${crawlId}`,
            message: e instanceof Error ? e.message : JSON.stringify(e),
            status: 0,
          }),
      ),
    )
    return decoded.result
  })

export const crawlResults = (
  auth: AuthConfig,
  crawlId: string,
  params?: Record<string, string>,
): Effect.Effect<unknown, ApiError, HttpClient.HttpClient> =>
  Effect.gen(function* () {
    const response = yield* getRequest(auth, `/crawl/${crawlId}`, params)
    const text: string = yield* response.text.pipe(
      Effect.mapError(
        (error) =>
          new ApiError({
            endpoint: `/crawl/${crawlId}`,
            message: error instanceof Error ? error.message : JSON.stringify(error),
            status: 0,
          }),
      ),
    )
    const parsed: unknown = JSON.parse(text)
    return parsed
  })

export const crawlList = (auth: AuthConfig): Effect.Effect<unknown, ApiError, HttpClient.HttpClient> =>
  Effect.gen(function* () {
    const response = yield* getRequest(auth, '/crawl')
    const text: string = yield* response.text.pipe(
      Effect.mapError(
        (error) =>
          new ApiError({
            endpoint: '/crawl',
            message: error instanceof Error ? error.message : JSON.stringify(error),
            status: 0,
          }),
      ),
    )
    const parsed: unknown = JSON.parse(text)
    return parsed
  })
