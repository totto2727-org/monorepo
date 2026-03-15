// oxlint-disable class-methods-use-this
// oxlint-disable max-classes-per-file

import { Data, Effect } from 'effect'

import * as Context from '#@/feature/share/lib/hono/context.ts'

export class BadRequest extends Data.TaggedError('http/error/BadRequest') {
  makeResponseEffect() {
    return Effect.succeed(Context.get().json({ error: 'Bad Request' }, 400))
  }
}

export class Unauthorized extends Data.TaggedError('http/error/Unauthorized') {
  makeResponseEffect() {
    return Effect.succeed(Context.get().json({ error: 'Unauthorized' }, 401))
  }
}

export class Forbidden extends Data.TaggedError('http/error/Forbidden') {
  makeResponseEffect() {
    return Effect.succeed(Context.get().json({ error: 'Forbidden' }, 403))
  }
}

export class NotFound extends Data.TaggedError('http/error/NotFound') {
  makeResponseEffect() {
    return Effect.succeed(Context.get().json({ error: 'Not Found' }, 404))
  }
}

export class InternalServerError extends Data.TaggedError('http/error/InternalServerError') {
  makeResponseEffect() {
    return Effect.succeed(Context.get().json({ error: 'Internal Server Error' }, 500))
  }
}
