import { ClerkProvider } from "@clerk/react-router"
import { rootAuthLoader } from "@clerk/react-router/ssr.server"
import { Outlet } from "react-router"
import type { Route } from "./+types/app._auth"

export async function loader(args: Route.LoaderArgs) {
  return rootAuthLoader(args)
}

export default function AuthLayout({ loaderData }: Route.ComponentProps) {
  return (
    <ClerkProvider
      loaderData={loaderData}
      signInFallbackRedirectUrl="/"
      signUpFallbackRedirectUrl="/"
    >
      <Outlet />
    </ClerkProvider>
  )
}
