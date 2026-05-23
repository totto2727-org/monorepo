import { Effect, Layer, Ref } from 'effect'

import * as Sender from './sender.ts'

const makeMockLayer = (): Layer.Layer<Sender.EmailSender> =>
  Layer.effect(
    Sender.Service,
    Effect.gen(function* () {
      const history = yield* Ref.make<readonly Sender.SendParams[]>([])
      return {
        send: (params) => Ref.update(history, (xs) => [...xs, params]),
      }
    }),
  )

export const layer = makeMockLayer()
