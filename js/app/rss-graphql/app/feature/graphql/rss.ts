import { FeedType as FeedTypeEnum } from '@mikaelporttila/rss'
import { Effect, Predicate, Runtime, Schema } from '@totto/function/effect'
import { NonEmptyStringResolver } from 'graphql-scalars'

import { fetch } from '../rss.ts'
import { builder } from './builder.js'

const feedTypeEnumToLiteral = Schema.transformLiterals(
  [FeedTypeEnum.Atom, 'ATOM'],
  [FeedTypeEnum.JsonFeed, 'JSONFeed'],
  [FeedTypeEnum.Rss1, 'RSS_1_0'],
  [FeedTypeEnum.Rss2, 'RSS_2_0'],
)
const decodeSyncFeedType = Schema.decodeSync(feedTypeEnumToLiteral)

type Type = typeof feedTypeEnumToLiteral.Type

interface Size {
  width: number
  height: number
}

interface Image {
  url: string
  link: string
  title: string
  size?: Size
}

interface Item {
  id: string
  author: string
  title: string
  description: string
  links: string[]
  publishedAt: string
  updatedAt: string
}

interface Feed {
  type: Type
  id: string
  title: string
  description: string
  links: string[]
  image?: Image
  updatedAt: string
  items: Item[]
}

interface FeedResponse {
  feedURL: string
  feed: Feed
}

const nonEmptyStringScalar = builder.addScalarType('NonEmptyString', NonEmptyStringResolver)
const feedTypeEnum = builder.enumType('FeedType', {
  values: feedTypeEnumToLiteral.members.map((v) => v.to.literals[0]),
})

const sizeRef = builder.objectRef<Size>('Size')
const imageRef = builder.objectRef<Image>('Image')
const itemRef = builder.objectRef<Item>('Item')
const feedRef = builder.objectRef<Feed>('Feed')
const feedResponseRef = builder.objectRef<FeedResponse>('FeedResponse')

sizeRef.implement({
  fields: (t) =>
    ({
      height: t.exposeInt('height'),
      width: t.exposeInt('width'),
    }) satisfies Record<keyof Size, unknown>,
})

imageRef.implement({
  fields: (t) =>
    ({
      link: t.expose('link', { type: nonEmptyStringScalar }),
      size: t.expose('size', {
        nullable: true,
        type: sizeRef,
      }),
      title: t.exposeString('title'),
      url: t.exposeString('url'),
    }) satisfies Record<keyof Image, unknown>,
})

itemRef.implement({
  fields: (t) =>
    ({
      author: t.exposeString('author'),
      description: t.exposeString('description'),
      id: t.exposeString('id'),
      links: t.exposeStringList('links'),
      publishedAt: t.exposeString('publishedAt'),
      title: t.exposeString('title'),
      updatedAt: t.exposeString('updatedAt'),
    }) satisfies Record<keyof Item, unknown>,
})

feedRef.implement({
  fields: (t) =>
    ({
      description: t.exposeString('description'),
      id: t.exposeString('id'),
      image: t.expose('image', {
        nullable: true,
        type: imageRef,
      }),
      items: t.expose('items', {
        type: t.listRef(itemRef),
      }),
      links: t.exposeStringList('links'),
      title: t.exposeString('title'),
      type: t.expose('type', {
        type: feedTypeEnum,
      }),
      updatedAt: t.exposeString('updatedAt'),
    }) satisfies Record<keyof Feed, unknown>,
})

feedResponseRef.implement({
  fields: (t) =>
    ({
      feed: t.expose('feed', {
        type: feedRef,
      }),
      feedURL: t.exposeString('feedURL'),
    }) satisfies Record<keyof FeedResponse, unknown>,
})

builder.queryType({
  fields: (t) => ({
    queryFeed: t.field({
      args: {
        feedURL: t.arg.string(),
      },
      nullable: false,
      resolve: (_, args, context) =>
        Effect.gen(function*  resolve() {
          const fetcher = yield* fetch
          const rss = yield* fetcher(args.feedURL)

          return {
            feed: {
              description: rss.description ?? '',
              id: rss.id,
              image: rss.image && {
                link: rss.image.link ?? '',
                size:
                  Predicate.isNotNullable(rss.image.width) && Predicate.isNotNullable(rss.image.height)
                    ? {
                        height: rss.image.height,
                        width: rss.image.width,
                      }
                    : undefined,
                title: rss.image.title ?? '',
                url: rss.image.url ?? '',
              },
              items: rss.entries
                .filter((entry) => Predicate.isNotNullable(entry.id))
                .map((entry) => ({
                  author: entry.author?.name ?? '',
                  description: entry.description?.value ?? '',
                  id: entry.id ?? '',
                  links: entry.links.map((link) => link.href).filter((v) => Predicate.isNotNullable(v)),
                  publishedAt:
                    entry.published?.toISOString() ?? entry.updated?.toISOString() ?? new Date().toISOString(),
                  title: entry.title?.value ?? '',
                  updatedAt: entry.updated?.toISOString() ?? entry.published?.toISOString() ?? new Date().toISOString(),
                })),
              links: rss.links,
              title: rss.title.value ?? '',
              type: decodeSyncFeedType(rss.type),
              updatedAt:
                rss.updateDate?.toISOString() ??
                rss.created?.toISOString() ??
                rss.published?.toISOString() ??
                new Date().toISOString(),
            },
            feedURL: args.feedURL,
          } as const satisfies FeedResponse
        }).pipe(Runtime.runPromise(context.runtime)),
      type: feedResponseRef,
      validate: Schema.standardSchemaV1(
        Schema.Struct({
          feedURL: Schema.URL,
        }),
      ),
    }),
  }),
})
