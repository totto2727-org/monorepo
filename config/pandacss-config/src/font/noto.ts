import type { TextStyles } from "@pandacss/types";

function notoBase(
  description: string,
  value?: TextStyles[string]["value"],
): TextStyles[string] {
  return {
    description,
    value: {
      fontFamily: "'Noto Sans JP', sans-serif",
      fontWeight: "400",
      fontSize: "1.5rem",
      lineHeight: "1.5",
      textDecoration: "none",
      textTransform: "none",
      ...(value ?? {}),
    },
  };
}

export const noto: TextStyles = {
  notoP: notoBase("noto p"),
  notoSpan: notoBase("noto span"),
  notoA: notoBase("noto a", { textDecoration: "underline", fontWeight: 500 }),
  notoH1: notoBase("noto h1", {
    fontWeight: 700,
    fontSize: "2.5rem",
  }),
  notoH2: notoBase("noto h2", { fontWeight: 700, fontSize: "2.25rem" }),
  notoH3: notoBase("noto h3", { fontWeight: 700, fontSize: "2rem" }),
  notoH4: notoBase("noto h4", { fontWeight: 700, fontSize: "1.75rem" }),
};
