import * as pulumi from '@pulumi/pulumi'
import { afterAll, beforeAll, describe, expect, test, vi } from 'vite-plus/test'

const applicationType = 'cloudflare:index/zeroTrustAccessApplication:ZeroTrustAccessApplication'
const policyType = 'cloudflare:index/zeroTrustAccessPolicy:ZeroTrustAccessPolicy'
const tagType = 'cloudflare:index/zeroTrustAccessTag:ZeroTrustAccessTag'
const resources: pulumi.runtime.MockResourceArgs[] = []
let outputs: {
  cloudflareOsAccessAudience: string
  cloudflareOsAccessDomain: string
  projektorAccessAudience: string
  projektorAccessDomain: string
}

const mocks: pulumi.runtime.Mocks = {
  call: (args) => {
    throw new Error(`Unexpected provider invocation: ${args.token}`)
  },
  newResource: (args) => {
    resources.push(args)
    return {
      id: `id-${args.name}`,
      // oxlint-disable-next-line typescript/no-unsafe-assignment -- Pulumi declares provider mock inputs as any and expects them echoed as state.
      state: args.type === applicationType ? { ...args.inputs, aud: `aud-${args.name}` } : args.inputs,
    }
  },
}

beforeAll(async () => {
  vi.stubEnv('CLOUDFLARE_ACCOUNT_ID', 'test-account')
  pulumi.runtime.setAllConfig({
    'access:cloudflareOsDomain': 'cloudflare.totto2727.dev',
    'access:projektorDomain': 'projektor.totto2727.dev',
  })
  await pulumi.runtime.setMocks(mocks, 'cloudflare', 'production')

  const stack = await import('../index.ts')
  const { promise, resolve } = Promise.withResolvers<typeof outputs>()
  pulumi
    .all([
      stack.cloudflareOsAccessAudience,
      stack.cloudflareOsAccessDomain,
      stack.projektorAccessAudience,
      stack.projektorAccessDomain,
    ])
    .apply(([cloudflareOsAccessAudience, cloudflareOsAccessDomain, projektorAccessAudience, projektorAccessDomain]) => {
      resolve({ cloudflareOsAccessAudience, cloudflareOsAccessDomain, projektorAccessAudience, projektorAccessDomain })
    })
  outputs = await promise
})

afterAll(() => {
  pulumi.runtime.setAllConfig({})
  vi.unstubAllEnvs()
})

describe('Deployment Access applications', () => {
  test('protects each full hostname with only the administrator SAML policy', () => {
    const applications = resources.filter((resource) => resource.type === applicationType)
    expect(applications).toHaveLength(2)

    for (const [name, domain] of [
      ['projektor', 'projektor.totto2727.dev'],
      ['cloudflare-os', 'cloudflare.totto2727.dev'],
    ]) {
      expect(applications.find((application) => application.name === `iac-prod-${name}`)).toMatchObject({
        inputs: {
          accountId: 'test-account',
          allowedIdps: ['id-iac-prod-aws-saml-identity-provider'],
          appLauncherVisible: true,
          autoRedirectToIdentity: true,
          destinations: [{ type: 'public', uri: domain }],
          domain,
          name: `iac-prod-${name}`,
          policies: [{ id: 'id-iac-prod-deployment-admin', precedence: 1 }],
          sessionDuration: '24h',
          type: 'self_hosted',
        },
      })
    }
  })

  test('allows only the deployment administrator and requires the SAML group', () => {
    const policy = resources.find((resource) => resource.name === 'iac-prod-deployment-admin')
    expect(policy).toMatchObject({
      inputs: {
        accountId: 'test-account',
        decision: 'allow',
        includes: [{ email: { email: 'kaihatu.totto2727@gmail.com' } }],
        name: 'iac-prod-deployment-admin',
        requires: [{ group: { id: 'id-iac-prod-saml-access-group' } }],
        sessionDuration: '24h',
      },
      type: policyType,
    })
    expect(resources.find((resource) => resource.name === 'iac-prod-saml-access-group')).toMatchObject({
      inputs: { includes: [{ loginMethod: { id: 'id-iac-prod-aws-saml-identity-provider' } }] },
    })
    expect(resources.filter((resource) => resource.type === policyType)).toHaveLength(2)
  })

  test('creates ownership tags once and attaches them to both applications', () => {
    const tagNames = [
      'environment:production',
      'managed-by:pulumi',
      'pulumi-project:cloudflare',
      'pulumi-stack:production',
      'repository:totto2727-org/monorepo',
    ]
    const registeredTags = resources.filter((resource) => resource.type === tagType)
    expect(registeredTags).toHaveLength(tagNames.length)
    expect(registeredTags).toMatchObject(tagNames.map((name) => ({ inputs: { accountId: 'test-account', name } })))
    for (const application of resources.filter((resource) => resource.type === applicationType)) {
      expect(application.inputs).toMatchObject({ tags: tagNames })
    }
  })

  test('exports distinct provider audiences rather than application or policy IDs', () => {
    expect(outputs).toEqual({
      cloudflareOsAccessAudience: 'aud-iac-prod-cloudflare-os',
      cloudflareOsAccessDomain: 'cloudflare.totto2727.dev',
      projektorAccessAudience: 'aud-iac-prod-projektor',
      projektorAccessDomain: 'projektor.totto2727.dev',
    })
  })

  test.each(['cloudflareOsDomain', 'projektorDomain'])(
    'requires explicit %s configuration in another stack',
    async (key) => {
      vi.resetModules()
      pulumi.runtime.setAllConfig({
        [`access:${key === 'projektorDomain' ? 'cloudflareOsDomain' : 'projektorDomain'}`]: 'staging.example.com',
      })
      await pulumi.runtime.setMocks(mocks, 'cloudflare', 'staging')

      await expect(import('./access-application.ts')).rejects.toThrow(
        `Missing required configuration variable 'access:${key}'`,
      )
      expect(resources.filter((resource) => resource.type === applicationType)).toHaveLength(2)
    },
  )
})
