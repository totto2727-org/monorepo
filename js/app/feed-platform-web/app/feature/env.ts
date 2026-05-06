import { Context, Layer } from 'effect'

export interface Type {
  readonly ENV: 'production' | 'development'
}

export const Service = Context.Service<Type>('@app/feed-platform-web/feature/env/Service')

export const makeLayer = (env: Type) => Layer.succeed(Service, env)
