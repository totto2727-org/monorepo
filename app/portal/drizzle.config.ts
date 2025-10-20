import { defineConfig } from "drizzle-kit"

export default defineConfig({
  dbCredentials: {
    // biome-ignore lint/style/noNonNullAssertion: required
    accountId: process.env.CLOUDFLARE_ACCOUNT_ID!,
    // biome-ignore lint/style/noNonNullAssertion: required
    databaseId: process.env.CLOUDFLARE_DATABASE_ID!,
    // biome-ignore lint/style/noNonNullAssertion: required
    token: process.env.CLOUDFLARE_D1_TOKEN!,
  },
  dialect: "sqlite",
  driver: "d1-http",
  out: "./migrations",
  schema: "./src/schema.ts",
})
