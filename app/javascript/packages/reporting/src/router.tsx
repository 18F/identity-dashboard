import { cloneElement, toChildArray, VNode, ComponentChildren } from "preact";
import {
  Router as BaseRouter,
  Link as BaseLink,
  route as baseRoute,
  RoutableProps,
} from "preact-router";

interface RouterProps {
  children: ComponentChildren;
}

const appElement = document.getElementById("app");
const BASE_URL = appElement?.getAttribute("data-base-url") || "";
console.log("Using BASE_URL from data attribute:", BASE_URL);

export const getFullPath = (path = "", basePath = BASE_URL): string =>
  path.startsWith(basePath) ? path : basePath + path;

export function Router({ children }: RouterProps): VNode {
  const childrenAsArray = toChildArray(children) as VNode<RoutableProps>[];

  return (
    <BaseRouter>
      {childrenAsArray.map(
        (child) =>
          typeof child === "object" && cloneElement(child, { path: getFullPath(child.props.path) })
      )}
    </BaseRouter>
  );
}

// export function Link(
//   props: { href?: string } & Omit<preact.JSX.HTMLAttributes<HTMLAnchorElement>, "href">
// ): VNode {
//   const { href, ...otherProps } = props;
//   return <BaseLink href={getFullPath(href || "")} {...otherProps} />;
// }

export function route(path: string): boolean | undefined {
  const fullPath = getFullPath(path);
  console.log("Routing to full path:", fullPath);
  return baseRoute(getFullPath(path));
}
