import { Effect, Layer } from 'effect'

import * as Env from '#@/feature/env.ts'

import * as Sender from './sender.ts'

const CLOUDFLARE_API_BASE = 'https://api.cloudflare.com'

export interface Config {
  readonly accountId: string
  readonly apiToken: string
  readonly fromAddress: string
}

const buildEndpoint = (accountId: string): string => `${CLOUDFLARE_API_BASE}/client/v4/accounts/${accountId}/email/send`

export const makeImpl = (config: Config): Sender.EmailSender => ({
  send: (params) =>
    Effect.tryPromise({
      catch: (cause) =>
        new Sender.EmailSendError({
          message: cause instanceof Error ? cause.message : String(cause),
        }),
      try: () =>
        fetch(buildEndpoint(config.accountId), {
          body: JSON.stringify({
            from: { email: config.fromAddress },
            html: params.html,
            subject: params.subject,
            text: params.text,
            to: [{ email: params.to }],
          }),
          headers: {
            Authorization: `Bearer ${config.apiToken}`,
            'Content-Type': 'application/json',
          },
          method: 'POST',
        }),
    }).pipe(
      Effect.flatMap((response) =>
        response.ok
          ? Effect.void
          : Effect.fail(
              new Sender.EmailSendError({
                message: `Cloudflare Email Send API returned status ${response.status}`,
              }),
            ),
      ),
    ),
})

export const makeLayer = (config: Config) => Layer.succeed(Sender.Service, makeImpl(config))

export const layer = Layer.effect(
  Sender.Service,
  Effect.gen(function* () {
    const env = yield* Env.Service
    return makeImpl({
      accountId: env.CLOUDFLARE_ACCOUNT_ID,
      apiToken: env.CLOUDFLARE_EMAIL_API_TOKEN,
      fromAddress: env.MAIL_FROM_ADDRESS,
    })
  }),
)
