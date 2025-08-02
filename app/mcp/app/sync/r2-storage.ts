export async function save(
  bucket: R2Bucket,
  key: string,
  data: string,
): Promise<void> {
  await bucket.put(key, data)
}
