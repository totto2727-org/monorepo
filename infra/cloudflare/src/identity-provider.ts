import * as cloudflare from "@pulumi/cloudflare"
import * as config from "./config.js"

export const awsSaml = new cloudflare.ZeroTrustAccessIdentityProvider(
  "aws-saml-identity-provider",
  {
    accountId: config.accountID,
    config: {
      attributes: ["email", "groups", "sub", "name"],
      emailAttributeName: "email",
      idpPublicCerts: [
        `
-----BEGIN CERTIFICATE-----
MIIDBzCCAe+gAwIBAgIFALZdmCYwDQYJKoZIhvcNAQELBQAwRTEWMBQGA1UEAwwN
YW1hem9uYXdzLmNvbTENMAsGA1UECwwESURBUzEPMA0GA1UECgwGQW1hem9uMQsw
CQYDVQQGEwJVUzAeFw0yNDAzMTkxMjQ2NTVaFw0yOTAzMTkxMjQ2NTVaMEUxFjAU
BgNVBAMMDWFtYXpvbmF3cy5jb20xDTALBgNVBAsMBElEQVMxDzANBgNVBAoMBkFt
YXpvbjELMAkGA1UEBhMCVVMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
AQDF0OKkT45yJ63yTUJywjqFhijlYeMQY2C88Hf4NlhHIeYJVCz8rc2sfaEOSsIW
MTCsuIN5KivwEdDFxAz210JrbLeeIWTF6TfMXC5Diqmv8DEca8VtcoPttpU2YkTC
nq+1ftxQudKI1NuscvKk79f9DvDR1U5S69z6kZygNDaFxSwuq6IO6Bp3CBRCkErf
WYqnpCJoOgq6OgoMWAFMh1pcf06c0ZGSB4468a9rRTlcWcA6yikXMPWiFj/QfXnW
rBI2C0ENHuZc8nS91yX5CC0cSNS/Ud5HFyp513HHRZHm5DdYIuCgU34IS3CkcHt/
CsLuYBxr87U9yhK248reJznpAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAJxY2Dna
ORkbgCEHe82lziL0gM69Vw6HKP0QdyUcUdJcxWO4ayBEAxLjBkm4mkPlSDRhs+1s
mYH6v7Bo86QCEMh/IfuX9GiYIkVSGjxpoP2T3TD2WiJUi+dau+qD0sSri/vYdtth
l70gPQIcLsK37heTuRsA0opHyp/eO23zHZtkQbXgBvqrEEeh4YXuyPL9zNyiSN2c
U9HV6tGa5p8dAWvI5wbK6026scmuWpiJwaI4cYOnNLUgN+vimXUQVqWs2TRiBzxU
5CBJZLyoXg0yt9E9sN9MI5swaCU4+6yNpRDr3Qq2MoKRl5YQ4MuJBbznwPYA4TFA
U14U+SF7/wpBQvc=
-----END CERTIFICATE-----
`.trim(),
      ],
      issuerUrl:
        "https://portal.sso.ap-northeast-1.amazonaws.com/saml/metadata/MjMzNDI4NDg2Njk0X2lucy1jZmM5ZWJlMDdkYTNkOTcz",
      signRequest: true,
      ssoTargetUrl:
        "https://portal.sso.ap-northeast-1.amazonaws.com/saml/assertion/MjMzNDI4NDg2Njk0X2lucy1jZmM5ZWJlMDdkYTNkOTcz",
    },
    name: "SAML（AWS IAM）",
    type: "saml",
  },
  {
    protect: true,
  },
)
