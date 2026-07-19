import * as cloudflare from '@pulumi/cloudflare'

import * as config from './config.ts'

export const awsSaml = new cloudflare.ZeroTrustAccessIdentityProvider(
  config.resourceName('aws-saml-identity-provider'),
  {
    accountId: config.accountID,
    config: {
      attributes: ['email', 'groups', 'sub', 'name'],
      emailAttributeName: 'email',
      idpPublicCerts: [
        `
-----BEGIN CERTIFICATE-----
MIIDBjCCAe6gAwIBAgIEPm9NETANBgkqhkiG9w0BAQsFADBFMRYwFAYDVQQDDA1h
bWF6b25hd3MuY29tMQ0wCwYDVQQLDARJREFTMQ8wDQYDVQQKDAZBbWF6b24xCzAJ
BgNVBAYTAlVTMB4XDTI2MDcxODEzNDg0N1oXDTMxMDcxODEzNDg0N1owRTEWMBQG
A1UEAwwNYW1hem9uYXdzLmNvbTENMAsGA1UECwwESURBUzEPMA0GA1UECgwGQW1h
em9uMQswCQYDVQQGEwJVUzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
ANdvichSyKxbrPO5ce904JgpVqfIFJgdaDM+TxA+AT4A4S0nfDUItlcDVjdIO3lV
BYBMjUc3AvnRdGszfA7NAkBlaJXLIFeAApyJlW//OC3IUML6N/ka8//LdaAozg9P
W+xSUL4yv6SNN+i/8B907/ghno8+vt8hKIVH/ODbnjRzVxuRgUwvjzDRQQtXG91h
1+/tTVHWlTTMrzfmAsrlK/NuoGpQoJY1pRSnFAk1l3eciPs53q8fwxvijCn1GPgC
lB+neIsZfanFvULibyZx8qu4++kymzB+YbRnrBYgA7d6L/vUN+K2eyJVEpJLWSeP
kbAPBgBMxPphBh7Kdl7glLcCAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAGQJrSZ7K
ztBOY4u5/4FR33PNfxMCxwuC6xHAnFDibjqSunC+S5qP/c2C05gmy9ycp6e7VnMT
qI4kvYs1SGr8wQ9A2vAdh6zfNnXsGeoROS5URdDAWz5DAfojxiqBKE0fEdr6hJJD
73eHJR+5PlHeVnRRDSc69YfjCgWRP0cASD6AoHokeYChYf+VfHeb66QzYnyZrdji
XGZHPIDnBqP2k85Zu4iPrKgSON8500Yw4JnXSrk3YGlOGR1PGrB5kFHk2YPrgLab
EcP2tKY+JBEwv6L8EgXxXSiqF69Hq6Y5F8v0pSvAY3oXQKa7YU/qhx/KR4isnbOG
531fKCBCSCT/DQ==
-----END CERTIFICATE-----
`.trim(),
      ],
      issuerUrl:
        'https://portal.sso.ap-northeast-1.amazonaws.com/saml/assertion/MjMzNDI4NDg2Njk0X2lucy03NzU4NzI1ODU0MWUzZTUw',
      signRequest: true,
      ssoTargetUrl:
        'https://portal.sso.ap-northeast-1.api.aws/saml/assertion/MjMzNDI4NDg2Njk0X2lucy03NzU4NzI1ODU0MWUzZTUw',
    },
    name: config.resourceName('aws-saml'),
    type: 'saml',
  },
  config.protectedResourceOptions('aws-saml-identity-provider'),
)
