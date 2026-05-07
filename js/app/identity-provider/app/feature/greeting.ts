import { Context, Layer } from 'effect'

export interface Type {
  readonly greet: (name: string) => string
}

export const Service = Context.Service<Type>('@app/identity-provider/feature/greeting/Service')

export const layer = Layer.sync(Service, () => ({
  greet: (name: string) => `Hello, ${name}`,
}))
