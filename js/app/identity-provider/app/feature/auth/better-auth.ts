import { oauthProvider } from '@better-auth/oauth-provider'
import { passkey } from '@better-auth/passkey'
import { betterAuth } from 'better-auth'
import { jwt, magicLink } from 'better-auth/plugins'
import { Context, Effect, Layer, Predicate } from 'effect'

import { initialUserName } from '#@/feature/auth/user-name.ts'
import * as BetterAuthDB from '#@/feature/db/better-auth-kysely.ts'
import * as EmailSender from '#@/feature/email/sender.ts'
import * as Env from '#@/feature/env.ts'
import * as HonoContext from '#@/feature/share/lib/hono/context.ts'

const makeInstance = (db: BetterAuthDB.Instance, env: Env.Type, emailSender: EmailSender.EmailSender, origin: string) =>
  betterAuth({
    account: {
      fields: {
        accessToken: 'access_token',
        accessTokenExpiresAt: 'access_token_expires_at',
        accountId: 'account_id',
        createdAt: 'created_at',
        id: 'id',
        idToken: 'id_token',
        password: 'password',
        providerId: 'provider_id',
        refreshToken: 'refresh_token',
        refreshTokenExpiresAt: 'refresh_token_expires_at',
        scope: 'scope',
        updatedAt: 'updated_at',
        userId: 'user_id',
      },
      modelName: 'account',
    },
    basePath: '/api/v1/auth',
    baseURL: origin,
    database: { db, type: 'sqlite' },
    databaseHooks: {
      user: {
        create: {
          before: (user) => Promise.resolve({ data: { ...user, name: initialUserName(user) } }),
        },
      },
    },
    plugins: [
      passkey({
        origin,
        rpID: env.PASSKEY_RP_ID,
        rpName: 'identity-provider',
        schema: {
          passkey: {
            fields: {
              aaguid: 'aaguid',
              backedUp: 'backed_up',
              counter: 'counter',
              createdAt: 'created_at',
              credentialID: 'credential_id',
              deviceType: 'device_type',
              name: 'name',
              publicKey: 'public_key',
              transports: 'transports',
              userId: 'user_id',
            },
            modelName: 'passkey',
          },
        },
      }),
      magicLink({
        sendMagicLink: ({ email, url }) =>
          // oxlint-disable-next-line rules/no-effect-runtime-run -- better-auth callback requires a Promise boundary for the email sending Effect.
          Effect.runPromise(
            emailSender.send({
              subject: 'Login link',
              text: `Login here: ${url}`,
              to: email,
            }),
          ),
      }),
      oauthProvider({
        consentPage: '/login/oauth/consent',
        customAccessTokenClaims: ({ user }) => ({
          ...(Predicate.isString(user?.email) ? { email: user.email } : {}),
          token_use: 'access',
        }),
        idTokenExpiresIn: 3600,
        loginPage: '/login',
        refreshTokenExpiresIn: 2_592_000,
        schema: {
          oauthAccessToken: {
            fields: {
              clientId: 'client_id',
              createdAt: 'created_at',
              expiresAt: 'expires_at',
              id: 'id',
              referenceId: 'reference_id',
              refreshId: 'refresh_id',
              scopes: 'scope',
              sessionId: 'session_id',
              token: 'access_token',
              userId: 'user_id',
            },
            modelName: 'oauth_access_token',
          },
          oauthClient: {
            fields: {
              clientId: 'client_id',
              clientSecret: 'client_secret',
              contacts: 'contacts',
              createdAt: 'created_at',
              disabled: 'disabled',
              enableEndSession: 'enable_end_session',
              grantTypes: 'grant_types',
              icon: 'icon',
              id: 'id',
              metadata: 'metadata',
              name: 'name',
              policy: 'policy',
              postLogoutRedirectUris: 'post_logout_redirect_uris',
              public: 'public',
              redirectUris: 'redirect_uris',
              referenceId: 'reference_id',
              requirePKCE: 'require_pkce',
              responseTypes: 'response_types',
              scopes: 'scopes',
              skipConsent: 'skip_consent',
              softwareId: 'software_id',
              softwareStatement: 'software_statement',
              softwareVersion: 'software_version',
              subjectType: 'subject_type',
              tokenEndpointAuthMethod: 'token_endpoint_auth_method',
              tos: 'tos',
              type: 'type',
              updatedAt: 'updated_at',
              uri: 'uri',
              userId: 'user_id',
            },
            modelName: 'oauth_application',
          },
          oauthConsent: {
            fields: {
              clientId: 'client_id',
              createdAt: 'created_at',
              id: 'id',
              referenceId: 'reference_id',
              scopes: 'scope',
              updatedAt: 'updated_at',
              userId: 'user_id',
            },
            modelName: 'oauth_consent',
          },
          oauthRefreshToken: {
            fields: {
              authTime: 'auth_time',
              clientId: 'client_id',
              createdAt: 'created_at',
              expiresAt: 'expires_at',
              id: 'id',
              referenceId: 'reference_id',
              revoked: 'revoked',
              scopes: 'scope',
              sessionId: 'session_id',
              token: 'token',
              userId: 'user_id',
            },
            modelName: 'oauth_refresh_token',
          },
        },
        scopes: ['openid', 'profile', 'email', 'offline_access'],
        selectAccount: {
          page: '/login/select-account',
          shouldRedirect: () => true,
        },
        storeClientSecret: {
          hash: (clientSecret) => Promise.resolve(clientSecret),
          verify: (clientSecret, storedHash) => Promise.resolve(clientSecret === storedHash),
        },
        validAudiences: env.OAUTH_VALID_AUDIENCES.split(','),
      }),
      jwt({
        jwks: { keyPairConfig: { alg: 'ES256' } },
        schema: {
          jwks: {
            fields: {
              createdAt: 'created_at',
              expiresAt: 'expires_at',
              id: 'id',
              privateKey: 'private_key',
              publicKey: 'public_key',
            },
            modelName: 'jwks',
          },
        },
      }),
    ],
    secret: env.BETTER_AUTH_SECRET,
    session: {
      fields: {
        createdAt: 'created_at',
        expiresAt: 'expires_at',
        id: 'id',
        ipAddress: 'ip_address',
        token: 'token',
        updatedAt: 'updated_at',
        userAgent: 'user_agent',
        userId: 'user_id',
      },
      modelName: 'session',
      storeSessionInDatabase: true,
    },
    user: {
      fields: {
        createdAt: 'created_at',
        email: 'email',
        emailVerified: 'email_verified',
        id: 'id',
        image: 'image',
        name: 'name',
        updatedAt: 'updated_at',
      },
      modelName: 'user',
    },
    verification: {
      fields: {
        createdAt: 'created_at',
        expiresAt: 'expires_at',
        id: 'id',
        identifier: 'identifier',
        updatedAt: 'updated_at',
        value: 'value',
      },
      modelName: 'verification',
    },
  })

export type Instance = ReturnType<typeof makeInstance>

export const Service = Context.Service<Instance>('@app/identity-provider/feature/auth/better-auth/Service')

export const layer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const db = yield* BetterAuthDB.Service
    const env = yield* Env.Service
    const emailSender = yield* EmailSender.Service
    const { origin } = new URL(HonoContext.get().req.url)
    return makeInstance(db, env, emailSender, origin)
  }),
)
