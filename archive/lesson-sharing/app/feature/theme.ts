import { extendConfig, extendTheme } from "@yamada-ui/react"

const themeSchemes = {
  green: {
    semantics: {
      colorSchemes: { primary: "green" },
      colors: { primary: "green.500" },
    },
  },
  pink: {
    semantics: {
      colorSchemes: { primary: "pink" },
      colors: { primary: "pink.500" },
    },
  },
  purple: {
    semantics: {
      colorSchemes: { primary: "purple" },
      colors: { primary: "purple.500" },
    },
  },
}

export const theme = extendTheme({
  themeSchemes,
})()

export const config = extendConfig({
  initialColorMode: "system",
  initialThemeScheme: "base" satisfies keyof typeof themeSchemes | "base",
})
