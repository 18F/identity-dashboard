export function kebabCase(str: string): string {
  return str
    .replace(/[.\s]+/g, "-")
    .replace(/(.)([A-Z])/g, "$1-$2")
    .replace(/--/g, '-')
    .toLowerCase();
}
