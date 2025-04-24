import { VNode } from "preact";

declare module "preact-markdown" {
  export default function Markdown(opts: { markdown: string }): VNode;
}
