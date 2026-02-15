import { Predicate } from '@package/function/effect'
import * as path from 'node:path'

type HTMLBundleMap = Map<string, NonNullable<Bun.HTMLBundle['files']>[0]>

const makeFileResponse = (htmlBundleMap: HTMLBundleMap, basename: string) => {
  const file = htmlBundleMap.get(basename)
  if (Predicate.isNullable(file)) {
    return new Response(null, { status: 404 })
  }

  const bunFile = Bun.file(file.path)
  if (Predicate.isNullable(bunFile)) {
    return new Response(null, { status: 404 })
  }
  return new Response(bunFile, { headers: file.headers })
}

export const makeSPAWildcardRequestHandler = (
  htmlBundle: Bun.HTMLBundle,
  option: {
    isDev: boolean
  },
) => {
  // 開発サーバーではhtmlBundleを返すだけで適切に動作するため、そのまま返す
  if (option.isDev) {
    return htmlBundle
  }

  const htmlBundleMap: HTMLBundleMap = new Map()
  const bundledFileArray = htmlBundle.files ?? []

  for (const file of bundledFileArray) {
    htmlBundleMap.set(path.basename(file.path), file)
  }

  const htmlFile = bundledFileArray.find((f) => f.path.endsWith('.html'))
  if (Predicate.isNullable(htmlFile)) {
    throw new Error('No HTML file found')
  }

  return (c: Bun.BunRequest<string>) => {
    // HTML
    if (c.headers?.get('Accept')?.includes('text/html')) {
      return makeFileResponse(htmlBundleMap, path.basename(htmlFile.path))
    }

    // Other Assets
    return makeFileResponse(htmlBundleMap, path.basename(c.url))
  }
}
