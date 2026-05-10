import { describe, expect, test } from 'vite-plus/test'

import { stripLangTag, targetPath } from './path.ts'

describe('stripLangTag', () => {
  test('returns input unchanged when no lang segment', () => {
    expect(stripLangTag('hoge.md')).toBe('hoge.md')
    expect(stripLangTag('README.md')).toBe('README.md')
  })

  test('strips simple language tag (case-insensitive)', () => {
    expect(stripLangTag('hoge.ja.md')).toBe('hoge.md')
    expect(stripLangTag('hoge.en.md')).toBe('hoge.md')
    expect(stripLangTag('hoge.JA.md')).toBe('hoge.md')
  })

  test('strips region-qualified language tag (case-insensitive)', () => {
    expect(stripLangTag('hoge.ja-jp.md')).toBe('hoge.md')
    expect(stripLangTag('hoge.JA-jp.md')).toBe('hoge.md')
    expect(stripLangTag('hoge.zh-CN.md')).toBe('hoge.md')
  })

  test('compound .mbt.md is preserved as a unit', () => {
    expect(stripLangTag('hoge.mbt.md')).toBe('hoge.mbt.md')
  })

  test('strips lang segment that precedes a compound extension', () => {
    expect(stripLangTag('hoge.ja.mbt.md')).toBe('hoge.mbt.md')
    expect(stripLangTag('hoge.JA.mbt.md')).toBe('hoge.mbt.md')
    expect(stripLangTag('hoge.ja-jp.mbt.md')).toBe('hoge.mbt.md')
  })

  test('keeps segments that fail BCP 47 validation', () => {
    expect(stripLangTag('hoge.test.md')).toBe('hoge.test.md')
    expect(stripLangTag('hoge.invalid!.md')).toBe('hoge.invalid!.md')
  })

  test('returns input unchanged when no extension', () => {
    expect(stripLangTag('README')).toBe('README')
  })

  test('handles paths with directories', () => {
    expect(stripLangTag('docs/intro.ja.md')).toBe('docs/intro.md')
    expect(stripLangTag('docs/intro.ja.mbt.md')).toBe('docs/intro.mbt.md')
  })
})

describe('targetPath', () => {
  test('inserts lang before simple extension', () => {
    expect(targetPath('hoge.md', 'ja')).toBe('hoge.ja.md')
  })

  test('inserts lang before compound extension', () => {
    expect(targetPath('hoge.mbt.md', 'ja')).toBe('hoge.ja.mbt.md')
  })

  test('replaces existing simple lang tag', () => {
    expect(targetPath('hoge.en.md', 'ja')).toBe('hoge.ja.md')
  })

  test('replaces existing compound lang tag', () => {
    expect(targetPath('hoge.en.mbt.md', 'ja')).toBe('hoge.ja.mbt.md')
  })

  test('replaces existing region-qualified lang tag', () => {
    expect(targetPath('hoge.ja-jp.md', 'en')).toBe('hoge.en.md')
    expect(targetPath('hoge.zh-cn.mbt.md', 'ja')).toBe('hoge.ja.mbt.md')
  })

  test('keeps non-locale segments', () => {
    expect(targetPath('hoge.test.md', 'ja')).toBe('hoge.test.ja.md')
  })

  test('appends lang when no extension', () => {
    expect(targetPath('README', 'ja')).toBe('README.ja')
  })

  test('handles paths with directories', () => {
    expect(targetPath('docs/intro.md', 'ja')).toBe('docs/intro.ja.md')
    expect(targetPath('docs/intro.mbt.md', 'ja')).toBe('docs/intro.ja.mbt.md')
    expect(targetPath('docs/intro.en.md', 'ja')).toBe('docs/intro.ja.md')
  })

  test('re-translation to same lang produces identical output', () => {
    expect(targetPath('hoge.ja.md', 'ja')).toBe('hoge.ja.md')
    expect(targetPath('hoge.ja.mbt.md', 'ja')).toBe('hoge.ja.mbt.md')
  })
})
