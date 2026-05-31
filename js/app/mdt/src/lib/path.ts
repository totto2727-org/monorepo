import { Array } from 'effect'

const COMPOUND_EXTENSIONS: readonly string[] = ['.mbt.md']

const matchesLocaleSegment = (segment: string): boolean => {
  try {
    return Array.isArrayNonEmpty(Intl.getCanonicalLocales(segment))
  } catch {
    return false
  }
}

export const stripLangTag = (filePath: string): string => {
  for (const compound of COMPOUND_EXTENSIONS) {
    if (filePath.endsWith(compound)) {
      const stem = filePath.slice(0, -compound.length)
      const dotIndex = stem.lastIndexOf('.')
      if (dotIndex === -1) {
        return filePath
      }
      const tag = stem.slice(dotIndex + 1)
      return matchesLocaleSegment(tag) ? stem.slice(0, dotIndex) + compound : filePath
    }
  }
  const extIndex = filePath.lastIndexOf('.')
  if (extIndex === -1) {
    return filePath
  }
  const ext = filePath.slice(extIndex)
  const stem = filePath.slice(0, extIndex)
  const tagIndex = stem.lastIndexOf('.')
  if (tagIndex === -1) {
    return filePath
  }
  const tag = stem.slice(tagIndex + 1)
  return matchesLocaleSegment(tag) ? stem.slice(0, tagIndex) + ext : filePath
}

export const targetPath = (filePath: string, lang: string): string => {
  const stripped = stripLangTag(filePath)
  for (const compound of COMPOUND_EXTENSIONS) {
    if (stripped.endsWith(compound)) {
      return `${stripped.slice(0, -compound.length)}.${lang}${compound}`
    }
  }
  const extIndex = stripped.lastIndexOf('.')
  if (extIndex === -1) {
    return `${stripped}.${lang}`
  }
  return `${stripped.slice(0, extIndex)}.${lang}${stripped.slice(extIndex)}`
}
