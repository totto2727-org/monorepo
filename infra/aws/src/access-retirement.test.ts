import * as pulumi from '@pulumi/pulumi'
import { afterAll, beforeAll, describe, expect, test } from 'vite-plus/test'

const resources: pulumi.runtime.MockResourceArgs[] = []
const mocks: pulumi.runtime.Mocks = {
  call: (args) => {
    if (args.token !== 'aws:ssoadmin/getInstances:getInstances') {
      throw new Error(`Unexpected provider invocation: ${args.token}`)
    }
    return { arns: ['arn:test:instance'], identityStoreIds: ['test-identity-store'], region: 'ap-northeast-1' }
  },
  newResource: (args) => {
    resources.push(args)
    return {
      id: `id-${args.name}`,
      // oxlint-disable-next-line typescript/no-unsafe-assignment -- Pulumi mock inputs are any and must be echoed as resource state.
      state: { ...args.inputs, arn: `arn:${args.name}`, groupId: `id-${args.name}`, userId: `id-${args.name}` },
    }
  },
}

beforeAll(async () => {
  pulumi.runtime.setAllConfig({})
  await pulumi.runtime.setMocks(mocks, 'aws', 'production')
  await import('../index.ts')
  const modules = await Promise.all([
    import('./account.ts'),
    import('./group.ts'),
    import('./group-membership.ts'),
    import('./organization.ts'),
    import('./permission-set.ts'),
    import('./provider.ts'),
    import('./user.ts'),
  ])
  const { promise, resolve } = Promise.withResolvers<boolean>()
  pulumi
    .all(
      modules.flatMap((module: Record<string, pulumi.CustomResource>) =>
        Object.values(module).map((resource) => resource.id),
      ),
    )
    .apply(() => {
      resolve(true)
    })
  await promise
})

afterAll(() => {
  pulumi.runtime.setAllConfig({})
})

describe('AWS resources after Cloudflare SAML retirement', () => {
  test('does not register Cloudflare-specific resources or SAML applications', () => {
    expect(resources.filter((resource) => /cloudflare/iu.test(resource.name))).toEqual([])
    expect(
      resources.filter((resource) =>
        ['aws:ssoadmin/application:Application', 'aws:ssoadmin/applicationAssignment:ApplicationAssignment'].includes(
          resource.type,
        ),
      ),
    ).toEqual([])
  })

  test('preserves both users and the AWS account', () => {
    const users = resources.filter((resource) => resource.type === 'aws:identitystore/user:User')
    expect(users).toHaveLength(2)
    for (const [name, email] of [
      ['totto2727', 'kaihatu.totto2727@gmail.com'],
      ['test', 'hayato.2000.0727@gmail.com'],
    ]) {
      expect(users.find((user) => user.name === `iac-prod-${name}`)).toMatchObject({
        inputs: { emails: { value: email }, identityStoreId: 'test-identity-store', userName: name },
      })
    }
    expect(resources.filter((resource) => resource.type === 'aws:organizations/account:Account')).toMatchObject([
      { inputs: { closeOnDeletion: false, name: 'totto2727' }, name: 'totto2727-account' },
    ])
  })

  test('preserves the administrator group, membership and both account permission assignments', () => {
    expect(resources.filter((resource) => resource.type === 'aws:identitystore/group:Group')).toMatchObject([
      { inputs: { displayName: 'iac-prod-admin', identityStoreId: 'test-identity-store' }, name: 'iac-prod-admin' },
    ])
    expect(
      resources.filter((resource) => resource.type === 'aws:identitystore/groupMembership:GroupMembership'),
    ).toMatchObject([
      { inputs: { groupId: 'id-iac-prod-admin', memberId: 'id-iac-prod-totto2727' }, name: 'iac-prod-admin-totto2727' },
    ])
    const assignments = resources.filter(
      (resource) => resource.type === 'aws:ssoadmin/accountAssignment:AccountAssignment',
    )
    expect(assignments).toHaveLength(2)
    for (const [name, permission] of [
      ['administrator', 'administrator-access'],
      ['billing', 'billing'],
    ]) {
      expect(
        assignments.find((assignment) => assignment.name === `iac-prod-admin-${name}-permission-set`),
      ).toMatchObject({
        inputs: {
          instanceArn: 'arn:test:instance',
          permissionSetArn: `arn:iac-prod-${permission}`,
          principalId: 'id-iac-prod-admin',
          principalType: 'GROUP',
          targetId: 'id-totto2727-account',
          targetType: 'AWS_ACCOUNT',
        },
      })
    }
  })

  test('preserves the Pulumi OIDC provider and role trust', () => {
    expect(resources.find((resource) => resource.name === 'iac-prod-pulumi-oidc')).toMatchObject({
      inputs: { clientIdLists: ['aws:totto2727'], url: 'https://api.pulumi.com/oidc' },
      type: 'aws:iam/openIdConnectProvider:OpenIdConnectProvider',
    })
    const role = resources.find((resource) => resource.name === 'iac-prod-pulumi')
    expect(role?.type).toBe('aws:iam/role:Role')
    expect(role).toMatchObject({
      inputs: {
        assumeRolePolicy: {
          Statement: [
            { Action: 'sts:AssumeRoleWithWebIdentity', Principal: { Federated: 'arn:iac-prod-pulumi-oidc' } },
          ],
        },
      },
    })
  })
})
