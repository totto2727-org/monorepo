import { defineConfig } from "drizzle-kit"

export default defineConfig({
  dbCredentials: {
    accountId: "",
    databaseId: "be6fe799-2939-4424-9c55-29a96e66990b",
    token: "",
  },
  dialect: "sqlite",
  driver: "d1-http",
  out: "./migrations",
  schema: "./app/feature/drizzle/schema.ts",
})
