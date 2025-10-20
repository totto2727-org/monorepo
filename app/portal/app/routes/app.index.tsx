import { createFileRoute } from "@tanstack/react-router"
import { createServerFn } from "@tanstack/react-start"
import { Option } from "@totto/function/effect"
import { HStack, Text, VStack } from "@yamada-ui/react"
import { getContext } from "@/feature/hono"
import MaterialSymbolsKidStarOutlineSharp from "~icons/material-symbols/kid-star-outline-sharp"

export const getUser = createServerFn().handler(() => {
  return getContext().var.user.pipe(Option.getOrThrow)
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
      <VStack>
        <Text>{data.id}</Text>
        <VStack>
          {data.organizationArray.map((v) => (
            <Text key={v.id}>{v.id}</Text>
          ))}
        </VStack>
      </VStack>
    </VStack>
  )
}
