import { defineConfig } from "drizzle-kit"

export default defineConfig({
  dbCredentials: {
    accountId: "",
    databaseId: "db437e13-e164-443e-909a-46ecec24f119",
    token: "",
  },
  dialect: "sqlite",
  driver: "d1-http",
  out: "./drizzle",
  schema: "./app/drizzle.ts",
})
