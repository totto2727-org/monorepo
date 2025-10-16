import type { Env } from "@monorepo/tenant/hono"
import { createFileRoute } from "@tanstack/react-router"
import { createServerFn } from "@tanstack/react-start"
import { Option } from "@totto/function/effect"
import { HStack, Text, VStack } from "@yamada-ui/react"
import { getContext } from "hono/context-storage"
import MaterialSymbolsKidStarOutlineSharp from "~icons/material-symbols/kid-star-outline-sharp"

export const getUser = createServerFn().handler(() => {
  return getContext<Env.Env>().var.user.pipe(Option.getOrThrow)
})

export const Route = createFileRoute("/app/")({
  component: RouteComponent,
  loader() {
    return getUser()
  },
})

function RouteComponent() {
  const data = Route.useLoaderData()

  return (
    <VStack>
      <HStack alignItems="center" g="sm">
        <MaterialSymbolsKidStarOutlineSharp />
        <Text>Tanstack Start!!!</Text>
      </HStack>
      <HStack>
        <Text>{data.id}</Text>
        <HStack>
          {data.organizationIDArray.map((v) => (
            <Text>{v}</Text>
          ))}
        </HStack>
      </HStack>
    </VStack>
  )
}
