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

const { BASE_URL = "" } = import.meta.env ?? {};

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

export function Link({
  href,
  ...otherProps
}: preact.JSX.HTMLAttributes & { href?: string }): VNode {
  return <BaseLink href={getFullPath(href)} {...otherProps} />;
}

export function route(path: string): boolean | undefined {
  return baseRoute(getFullPath(path));
}
