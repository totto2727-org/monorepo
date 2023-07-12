import { MicroCMSClientInstance, MicroCMSContent, MicroCMSListContent, MicroCMSQueriesWithoutFields, MicroCMSRichEditorField, getList, getListDetail, } from "@/config/microCMS";
import type { MicroCMSImage } from "microcms-js-sdk";

export type BlogContent = MicroCMSContent<{
    title: string
    content: MicroCMSRichEditorField
    eyecatch: MicroCMSImage
}>

export type Blog = MicroCMSListContent<MicroCMSContent<BlogContent>>;

const endpoint = 'blogs'

export async function getBlogs<const T extends readonly (keyof Blog)[]>(client: MicroCMSClientInstance, fieldId: T, queries?: MicroCMSQueriesWithoutFields) {
    return await getList<Blog, T>(client, fieldId, { endpoint, queries });
};

export const getBlog = async <const T extends readonly (keyof Blog)[]>(
    client: MicroCMSClientInstance,
    contentId: string,
    fieldId: T,
    queries?: MicroCMSQueriesWithoutFields
) => {
    return await getListDetail<Blog, T>(client, fieldId, {
        endpoint,
        contentId,
        queries,
    });
};