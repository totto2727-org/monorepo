import { defineConfig } from "pncat"

export default defineConfig({
  allowedProtocols: ["workspace"],
  catalogRules: [
    {
      match: [/pulumi/],
      name: "pulumi",
    },
    {
      match: [/casbin/],
      name: "casbin",
    },
    {
      match: [/hono/],
      name: "hono",
    },
    {
      match: [/react/, /tanstack/],
      name: "react",
    },
    {
      match: [/drizzle/, /libsql/],
      name: "drizzle",
    },
    {
      match: [/daisyui/, /tailwind/],
      name: "ui",
    },
    {
      match: [/zod/, "@totto/function"],
      name: "util",
    },
    {
      match: [/graphql/, /@pothos/],
      name: "graphql",
    },
    { match: [/cloudflare/, /wrangler/], name: "cloudflare" },
    {
      match: [/biome/, /dprint/],
      name: "lint",
    },
    {
      match: [/vitest/, /playwright/],
      name: "test",
    },
    {
      match: [/vite/, /tsdown/, /typescript/],
      name: "build",
    },
    {
      match: [/tsconfig/],
      name: "tsconfig",
    },
    {
      match: [/turbo/, /pncat/],
      name: "cli",
    },
  ],
  force: false,
  ignoreOtherWorkspaces: true,
  ignorePaths: [
    "**/node_modules/**",
    "**/dist/**",
    "**/public/**",
    "**/fixture/**",
    "**/fixtures/**",
  ],
  mode: "detect",
  yes: false,
})
