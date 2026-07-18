import * as aws from '@pulumi/aws'

const clientId = 'aws:totto2727'
const domain = 'api.pulumi.com/oidc'
const subject = 'pulumi:environments:pulumi.organization.login:totto2727:currentEnvironment.name:aws/production'
export const pulumi = new aws.iam.OpenIdConnectProvider(
  'pulumi-oidc',
  {
    clientIdLists: [clientId],
    thumbprintLists: ['06b25927c42a721631c1efd9431e648fa62e1e39'],
    url: `https://${domain}`,
  },
  {
    protect: true,
  },
)

export const pulumiRole = new aws.iam.Role(
  'pulumi',
  {
    assumeRolePolicy: {
      Statement: [
        {
          Action: 'sts:AssumeRoleWithWebIdentity',
          Condition: {
            StringEquals: {
              [`${domain}:aud`]: clientId,
              [`${domain}:sub`]: subject,
            },
          },
          Effect: 'Allow',
          Principal: {
            Federated: pulumi.arn,
          },
        },
      ],
      Version: '2012-10-17',
    },
    name: 'pulumi',
  },
  {
    protect: true,
  },
)

const policyArns = [
  {
    arn: 'arn:aws:iam::aws:policy/AWSOrganizationsFullAccess',
    name: 'aws-organizations',
  },
  {
    arn: 'arn:aws:iam::aws:policy/AWSSSODirectoryAdministrator',
    name: 'sso-directory-administrator',
  },
  {
    arn: 'arn:aws:iam::aws:policy/AWSSOMasterAccountAdministrator',
    name: 'sso-master-account-administrator',
  },
  {
    arn: 'arn:aws:iam::aws:policy/IAMFullAccess',
    name: 'iam',
  },
] as const

export const pulumiRolePolicies = policyArns.map(
  ({ arn, name }) =>
    new aws.iam.RolePolicyAttachment(
      `pulumi-${name}`,
      {
        policyArn: arn,
        role: pulumiRole.name,
      },
      {
        protect: true,
      },
    ),
)

export const pulumiRolePoliciesExclusive = new aws.iam.RolePolicyAttachmentsExclusive(
  'pulumi-policies-exclusive',
  {
    policyArns: policyArns.map(({ arn }) => arn),
    roleName: pulumiRole.name,
  },
  {
    protect: true,
  },
)
