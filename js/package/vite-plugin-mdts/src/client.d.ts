interface MdtsMarkdownLinkReference {
  readonly hash: string | undefined
  readonly kind: 'vite-plugin-mdts/link'
  readonly targetPath: string
  readonly text: string | undefined
}

declare module '*?link' {
  const markdownLink: MdtsMarkdownLinkReference

  export default markdownLink
}

declare module '*&link' {
  const markdownLink: MdtsMarkdownLinkReference

  export default markdownLink
}
