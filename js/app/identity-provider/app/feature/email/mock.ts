import { Effect, Layer } from 'effect'

import * as Sender from './sender.ts'

export const layer: Layer.Layer<Sender.EmailSender> = Layer.succeed(Sender.Service, {
  send: (params) =>
    Effect.log('mock email send').pipe(
      Effect.annotateLogs({
        html: params.html ?? '',
        subject: params.subject,
        text: params.text,
        to: params.to,
      }),
    ),
})
