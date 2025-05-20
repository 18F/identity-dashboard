interface ImportMeta {
  env?: {
    BASE_URL: string;
  };
}

declare module "*.svg" {
  const content: string;
  export default content;
}
