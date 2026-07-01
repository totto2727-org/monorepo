import { deleteCookie, getCookie, setCookie } from 'hono/cookie'

import * as HonoContext from '#@/feature/share/lib/hono/context.ts'

export const loginReturnToCookieName = 'feed_platform_web_login_return_to'

const LOGIN_RETURN_TO_MAX_AGE_SECONDS = 10 * 60

const loginReturnToCookieOptions = {
  httpOnly: true,
  path: '/',
  sameSite: 'Lax',
} as const

export const getLoginReturnToCookie = (): string | undefined => getCookie(HonoContext.get(), loginReturnToCookieName)

export const setLoginReturnToCookie = (returnTo: string): void => {
  setCookie(HonoContext.get(), loginReturnToCookieName, returnTo, {
    ...loginReturnToCookieOptions,
    maxAge: LOGIN_RETURN_TO_MAX_AGE_SECONDS,
  })
}

export const deleteLoginReturnToCookie = (): void => {
  deleteCookie(HonoContext.get(), loginReturnToCookieName, loginReturnToCookieOptions)
}

export const deleteBetterAuthCookies = (headers: Headers): void => {
  for (const cookie of headers.getSetCookie()) {
    const [cookieName] = cookie.split('=')
    headers.append('Set-Cookie', `${cookieName}=; Max-Age=0; Path=/; HttpOnly; SameSite=Lax`)
  }
}
