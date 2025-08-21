import { defineConfig } from "pncat"

export default defineConfig({
  allowedProtocols: ["workspace"],
  catalogRules: [
    {
      match: [/@tsconfig/],
      name: "tsconfig",
    },
    {
      match: [/@pulumi/],
      name: "pulumi",
    },
    {
      match: [/@clerk/],
      name: "clerk",
    },
  ],
  depFields: {
    packageManager: false,
  },
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
