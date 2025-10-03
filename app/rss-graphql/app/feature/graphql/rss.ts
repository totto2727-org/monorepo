import type { FeedType as FeedTypeEnum } from "@mikaelporttila/rss"
import { Effect, Schema } from "@totto/function/effect"
import { builder } from "./builder.js"

type FeedType =
  | FeedTypeEnum.Atom
  | FeedTypeEnum.JsonFeed
  | FeedTypeEnum.Rss1
  | FeedTypeEnum.Rss2

type RSSBody = {
  feedType: FeedType
}

type RSS = {
  feedURL: string
  body: RSSBody
}

const rssBodyRef = builder.objectRef<RSSBody>("RSSBody")
const rssRef = builder.objectRef<RSS>("RSS")

rssBodyRef.implement({
  fields: (t) => ({
    feedType: t.exposeString("feedType", { nullable: false }),
  }),
})

rssRef.implement({
  fields: (t) => ({
    body: t.expose("body", {
      nullable: false,
      type: rssBodyRef,
    }),
    feedURL: t.exposeString("feedURL", { nullable: false }),
  }),
})

builder.queryType({
  fields: (t) => ({
    rss: t.field({
      args: {
        feedURL: t.arg.string({ required: true }),
      },
      nullable: false,
      resolve: async (_, args, context) => {
        const rss = await context.var
          .rssFetcher(args.feedURL)
          .pipe(Effect.runPromise)

        return {
          body: {
            feedType: rss.type,
          },
          feedURL: args.feedURL,
        } as const
      },
      type: rssRef,
      validate: Schema.standardSchemaV1(
        Schema.Struct({
          feedURL: Schema.URL,
        }),
      ),
    }),
  }),
})
