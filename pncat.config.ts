import { defineConfig } from "pncat"

export default defineConfig({
  allowedProtocols: ["workspace"],
  catalogRules: [
    {
      match: [/@pulumi/],
      name: "pulumi",
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
