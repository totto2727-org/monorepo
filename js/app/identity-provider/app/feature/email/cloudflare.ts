import { Effect, Layer } from 'effect'
// oxlint-disable-next-line import/no-unstable -- Thread 8 review: use Effect's HttpClient
import { FetchHttpClient, HttpBody, HttpClient, HttpClientRequest } from 'effect/unstable/http'

import * as Env from '#@/feature/env.ts'

import * as Sender from './sender.ts'

const CLOUDFLARE_API_BASE = 'https://api.cloudflare.com'

export interface Config {
  readonly accountId: string
  readonly apiToken: string
  readonly fromAddress: string
}

const buildEndpoint = (accountId: string): string =>
  `${CLOUDFLARE_API_BASE}/client/v4/accounts/${accountId}/email/send`

const makeSend = (config: Config): Sender.EmailSender['send'] => (params) =>
  Effect.gen(function* () {
    const client = yield* HttpClient.HttpClient
    const request = HttpClientRequest.post(buildEndpoint(config.accountId), {
      body: HttpBody.jsonUnsafe({
        from: { email: config.fromAddress },
        html: params.html,
        personalizations: [{ to: [{ email: params.to }] }],
        subject: params.subject,
        text: params.text,
      }),
      headers: {
        Authorization: `Bearer ${config.apiToken}`,
        'Content-Type': 'application/json',
      },
    })
    const response = yield* client.execute(request).pipe(
      Effect.mapError(
        (cause) =>
          new Sender.EmailSendError({
            message: cause instanceof Error ? cause.message : String(cause),
          }),
      ),
    )
    if (response.status < 200 || response.status >= 300) {
      return yield* Effect.fail(
        new Sender.EmailSendError({
          message: `Cloudflare Email Send API returned status ${response.status}`,
        }),
      )
    }
  }).pipe(Effect.provide(FetchHttpClient.layer))

export const makeLayer = (config: Config) =>
  Layer.succeed(Sender.Service, { send: makeSend(config) })

export const layer = Layer.effect(
  Sender.Service,
  Effect.gen(function* () {
    const env = yield* Env.Service
    return {
      send: makeSend({
        accountId: env.CLOUDFLARE_ACCOUNT_ID,
        apiToken: env.CLOUDFLARE_EMAIL_API_TOKEN,
        fromAddress: env.MAIL_FROM_ADDRESS,
      }),
    }
  }),
)
