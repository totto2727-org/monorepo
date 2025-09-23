import tailwindcss from "./tailwind.css?raw"

export function Tailwind() {
  return import.meta.env.PROD ? (
    <link href="/asset/tailwind.css" rel="stylesheet" />
  ) : (
    <>
      <link
        href="https://cdn.jsdelivr.net/npm/daisyui@5"
        rel="stylesheet"
        type="text/css"
      />
      <link
        href="https://cdn.jsdelivr.net/npm/daisyui@5/themes.css"
        rel="stylesheet"
        type="text/css"
      />
      <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
      <style
        // @ts-expect-error
        // biome-ignore lint/security/noDangerouslySetInnerHtml: Required for this use case
        dangerouslySetInnerHTML={tailwindcss}
        // @ts-expect-error
        type="text/tailwindcss"
      ></style>
    </>
  )
}
