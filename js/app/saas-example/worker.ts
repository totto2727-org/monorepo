import { Container, getContainer } from '@cloudflare/containers'

export class App extends Container {
  override defaultPort = 3000
  override sleepAfter = '5m'
}

export default {
  fetch: (request: Request, env: Cloudflare.Env) => {
    // oxlint-disable-next-line no-explicit-any
    const containerInstance = getContainer(env.App as any)
    return containerInstance.fetch(request)
  },
}
