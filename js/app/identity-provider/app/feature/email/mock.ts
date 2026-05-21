import { Effect, Layer, Ref } from 'effect'

import * as Sender from './sender.ts'

const history = Effect.runSync(Ref.make<readonly Sender.SentEmail[]>([]))

export const layer = Layer.succeed(Sender.Service, {
  send: (params) => Ref.update(history, (xs) => [...xs, params]),
})

export const getAllSent = (): Effect.Effect<readonly Sender.SentEmail[]> => Ref.get(history)

export const clearSent = (): Effect.Effect<void> => Ref.set(history, [])
