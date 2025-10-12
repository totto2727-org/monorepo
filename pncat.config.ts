import { defineConfig } from "pncat"

export default defineConfig({
  allowedProtocols: ["workspace"],
  catalogRules: [
    {
      match: [/pulumi/],
      name: "pulumi",
    },
    {
      match: [/clerk/],
      name: "clerk",
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
      match: [/drizzle/, /libsql/],
      name: "drizzle",
    },
    {
      match: [/yamada/, /daisyui/, /tailwind/],
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
    {
      match: [/react/],
      name: "react",
    },
    { match: [/cloudflare/, /wrangler/], name: "cloudflare" },
    {
      match: [/biome/, /dprint/],
      name: "lint",
    },
    {
      match: [/vitest/, /rstest/, /playwright/],
      name: "test",
    },
    {
      match: [/vite/, /rslib/, /typescript/, /rsbuild/],
      name: "build",
    },
    {
      match: [/tsconfig/],
      name: "tsconfig",
    },
    {
      match: [/turbo/, /tsx/, /pncat/],
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
