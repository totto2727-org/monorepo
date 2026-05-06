import { boot } from 'vite-plugin-remix/client'

// Project-wide convention: any *.client.tsx is a clientEntry-bearing module.
// import.meta.glob は Vite のコンパイル時構文のため、この呼び出し位置はアプリ側
// (バンドラから見える consumer source) でなければならない。
boot({
  components: import.meta.glob('/app/**/*.client.tsx'),
})
