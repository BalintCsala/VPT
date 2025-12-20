export function sanitizeReference(name: string) {
  return name.replace("block/", "").replace("minecraft:", "");
}
