# hono-ui

```json
"prebuild:tailwindcss": "tailwindcss -i ./tailwind.css -o ./public/asset/tailwind.css",
```

```css
@import "tailwindcss";
/* biome-ignore lint/suspicious/noUnknownAtRules: required */
@plugin "daisyui";
/* biome-ignore lint/suspicious/noUnknownAtRules: required */
@source "./node_modules/hono-ui";
```
