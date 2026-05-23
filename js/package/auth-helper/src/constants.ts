/** HttpOnly session cookie name shared by frontend and backend auth flows. */
export const FEED_SESSION_COOKIE = 'feed-session'

/** Base path for OAuth endpoints. */
export const OAUTH_BASE_PATH = '/api/v1/auth/oauth'

/** OAuth client ID for the web app. */
export const OAUTH_CLIENT_ID = 'feed-platform-web'

/** OAuth scopes requested by the web app. */
export const OAUTH_SCOPES = ['openid', 'profile', 'email'] as const
