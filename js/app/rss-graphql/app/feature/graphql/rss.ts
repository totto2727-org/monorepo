import { FeedType as FeedTypeForRawFeed } from '@mikaelporttila/rss'
import { Effect, Predicate, Schema } from 'effect'
import { Literals } from 'effect/Schema'
import { NonEmptyStringResolver } from 'graphql-scalars'

import { makeRSSFetchClient } from './rss-fetch-client.ts'
import type { Builder } from './schema.ts'

const feedType = Literals(['ATOM', 'JSONFeed', 'RSS_1_0', 'RSS_2_0'])

type FeedType = typeof feedType.Type

const feedTypeDTO = Literals([
  FeedTypeForRawFeed.Atom,
  FeedTypeForRawFeed.JsonFeed,
  FeedTypeForRawFeed.Rss1,
  FeedTypeForRawFeed.Rss2,
])

const feedTypeFromDTO = feedTypeDTO.transform(feedType.literals)

const decodeFeedType = Schema.decodeEffect(feedTypeFromDTO)

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
  type: FeedType
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

//
export const initGraphQL = (builder: Builder) => {
  const nonEmptyStringScalar = builder.addScalarType('NonEmptyString', NonEmptyStringResolver)
  const feedTypeEnum = builder.enumType('FeedType', {
    values: feedType.literals,
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
          Effect.gen(function* () {
            const rssFetchClient = yield* makeRSSFetchClient
            const rss = yield* rssFetchClient(args.feedURL)

            return {
              feed: {
                description: rss.description ?? '',
                id: rss.id,
                image: rss.image && {
                  link: rss.image.link ?? '',
                  size:
                    Predicate.isNotNullish(rss.image.width) && Predicate.isNotNullish(rss.image.height)
                      ? {
                          height: rss.image.height,
                          width: rss.image.width,
                        }
                      : undefined,
                  title: rss.image.title ?? '',
                  url: rss.image.url ?? '',
                },
                items: rss.entries
                  .filter((entry) => Predicate.isNotNullish(entry.id))
                  .map((entry) => ({
                    author: entry.author?.name ?? '',
                    description: entry.description?.value ?? '',
                    id: entry.id ?? '',
                    links: entry.links.map((link) => link.href).filter((v) => Predicate.isNotNullish(v)),
                    publishedAt:
                      entry.published?.toISOString() ?? entry.updated?.toISOString() ?? new Date().toISOString(),
                    title: entry.title?.value ?? '',
                    updatedAt:
                      entry.updated?.toISOString() ?? entry.published?.toISOString() ?? new Date().toISOString(),
                  })),
                links: rss.links,
                title: rss.title.value ?? '',
                type: yield* decodeFeedType(rss.type),
                updatedAt:
                  rss.updateDate?.toISOString() ??
                  rss.created?.toISOString() ??
                  rss.published?.toISOString() ??
                  new Date().toISOString(),
              },
              feedURL: args.feedURL,
            } as const satisfies FeedResponse
          }).pipe(context.var.runtime.runPromise),
        type: feedResponseRef,
        validate: Schema.toStandardSchemaV1(
          Schema.Struct({
            feedURL: Schema.URLFromString,
          }),
        ),
      }),
    }),
  })
}
