import { useAuth } from "@clerk/react-router"
import { Stack, Text } from "@yamada-ui/react"

export default function User() {
  const auth = useAuth()
  return (
    <Stack>
      <Text>{auth.orgId}</Text>
      <Text>{auth.userId}</Text>
    </Stack>
  )
}
