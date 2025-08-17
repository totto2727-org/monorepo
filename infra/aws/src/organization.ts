import * as aws from "@pulumi/aws"

export const feature = new aws.iam.OrganizationsFeatures(
  "organization-feature",
  {
    enabledFeatures: ["RootSessions", "RootCredentialsManagement"],
  },
  {
    protect: true,
  },
)

export const passwordPolicy = new aws.iam.AccountPasswordPolicy(
  "password-policy",
  {
    allowUsersToChangePassword: false,
    minimumPasswordLength: 8,
    passwordReusePrevention: 5,
    requireLowercaseCharacters: true,
    requireNumbers: true,
    requireSymbols: true,
    requireUppercaseCharacters: true,
  },
  {
    protect: true,
  },
)
