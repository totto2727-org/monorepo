import { createFileRoute } from "@tanstack/react-router"
import { HStack, Text, VStack } from "@yamada-ui/react"
import MaterialSymbolsKidStarOutlineSharp from "~icons/material-symbols/kid-star-outline-sharp"

export const Route = createFileRoute("/app/")({
  component: RouteComponent,
})

function RouteComponent() {
  return (
    <VStack>
      <HStack alignItems="center" g="sm">
        <MaterialSymbolsKidStarOutlineSharp />
        <Text>Tanstack Start!!!</Text>
      </HStack>
    </VStack>
  )
}
