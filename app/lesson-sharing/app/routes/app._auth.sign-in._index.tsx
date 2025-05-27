import { RedirectToSignIn } from "@clerk/react-router"
import { getAuth } from "@clerk/react-router/ssr.server"
import { redirect } from "react-router"
import type { Route } from "./+types/app._auth.sign-in._index"

export const loader = async (args: Route.LoaderArgs) => {
  const auth = await getAuth(args)
  if (auth.userId) {
    return redirect("/app", 303)
  }
}

export default function SignIn() {
  return <RedirectToSignIn />
}
