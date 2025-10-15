import { createFileRoute } from "@tanstack/react-router"

export const Route = createFileRoute("/app/")({
  component: RouteComponent,
})

function RouteComponent() {
  return <div>Hello Tanstack Start!!!</div>
}
