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
    managedPolicyArns: [
      'arn:aws:iam::aws:policy/AWSOrganizationsFullAccess',
      'arn:aws:iam::aws:policy/AWSSSODirectoryAdministrator',
      'arn:aws:iam::aws:policy/AWSSSOMasterAccountAdministrator',
      'arn:aws:iam::aws:policy/IAMFullAccess',
    ],
    name: 'pulumi',
  },
  {
    protect: true,
  },
)
