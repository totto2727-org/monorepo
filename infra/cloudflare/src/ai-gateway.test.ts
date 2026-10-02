import * as pulumi from '@pulumi/pulumi'
import { afterAll, beforeAll, describe, expect, test, vi } from 'vite-plus/test'

const resources: pulumi.runtime.MockResourceArgs[] = []
let outputs: { baseUrl: string; gatewayId: string }

beforeAll(async () => {
  vi.stubEnv('CLOUDFLARE_ACCOUNT_ID', 'test-account')
  await pulumi.runtime.setMocks(
    {
      call: (args) => {
        throw new Error(`Unexpected provider invocation: ${args.token}`)
      },
      newResource: (args) => {
        resources.push(args)
        // oxlint-disable-next-line typescript/no-unsafe-assignment -- Pulumi declares mock inputs as any and expects them echoed as resource state.
        return { id: 'provider-resource-id', state: args.inputs }
      },
    },
    'cloudflare',
    'production',
  )

  const gateway = await import('./ai-gateway.ts')
  const { promise, resolve } = Promise.withResolvers<typeof outputs>()
  pulumi.all([gateway.aiGatewayBaseUrl, gateway.aiGatewayId]).apply(([baseUrl, gatewayId]) => {
    resolve({ baseUrl, gatewayId })
  })
  outputs = await promise
})

afterAll(() => {
  vi.unstubAllEnvs()
})

describe('AI Gateway', () => {
  test('registers one native gateway with authenticated, non-logging defaults', () => {
    expect(resources).toHaveLength(1)
    expect(resources[0]).toMatchObject({
      inputs: {
        accountId: 'test-account',
        aiGatewayId: 'iac-prod-ai-gateway',
        authentication: true,
        cacheInvalidateOnUpdate: true,
        cacheTtl: 0,
        collectLogs: false,
        rateLimitingInterval: 0,
        rateLimitingLimit: 0,
      },
      name: 'iac-prod-ai-gateway',
      type: 'cloudflare:index/aiGateway:AiGateway',
    })
  })

  test('exports a connection URL using the gateway ID rather than the provider resource ID', () => {
    expect(outputs).toEqual({
      baseUrl: 'https://gateway.ai.cloudflare.com/v1/test-account/iac-prod-ai-gateway',
      gatewayId: 'iac-prod-ai-gateway',
    })
  })
})
