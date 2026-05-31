import { Predicate } from 'effect'

export const b64urlToBuf = (s: string): ArrayBuffer => {
  const pad = '='.repeat((4 - (s.length % 4)) % 4)
  const b = (s + pad).replaceAll('-', '+').replaceAll('_', '/')
  const raw = atob(b)
  const buf = Uint8Array.from(raw, (ch) => ch.codePointAt(0) ?? 0)
  return buf.buffer
}

export const bufToB64url = (buf: ArrayBuffer): string => {
  const bytes = Array.from(new Uint8Array(buf), (byte) =>
    String.fromCodePoint(Predicate.isNumber(byte) ? byte : 0),
  ).join('')
  return btoa(bytes).replaceAll('+', '-').replaceAll('/', '_').replaceAll(/[=]/gu, '')
}
