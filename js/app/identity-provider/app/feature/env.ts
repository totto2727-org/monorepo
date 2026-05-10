import { Context, Layer } from 'effect'

export interface Type {
  readonly ENV: 'production' | 'development'
}

export const Service = Context.Service<Type>('@app/identity-provider/feature/env/Service')

// production code 用 layer。`process.env.NODE_ENV` を単一ソースに採用する。
// wrangler / vite が下記のとおり `NODE_ENV` を自動設定するため、追加の wrangler vars 設定は不要:
//   - `wrangler dev` / `vite` (dev)   → `process.env.NODE_ENV = 'development'`
//   - `wrangler deploy` / `vite build` → `process.env.NODE_ENV = 'production'`
// ref: https://developers.cloudflare.com/workers/wrangler/bundling/#node_env
export const layer = Layer.sync(
  Service,
  (): Type => ({
    ENV: process.env.NODE_ENV === 'production' ? 'production' : 'development',
  }),
)

// test 用 layer。明示値で注入することで Vitest 上での Logger 形式や ENV 振る舞いを固定できる。
export const makeLayer = (env: Type) => Layer.succeed(Service, env)
