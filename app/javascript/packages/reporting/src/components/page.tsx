import { ComponentChildren, VNode } from "preact";
import Header from "./header";

interface PageProps {
  path: string;
  children?: ComponentChildren;
  title: string;
}

function Page({ path, children, title }: PageProps): VNode {
  return (
    <>
      <Header path={path} />
      <div className="grid-container">
        <div className="grid-row">
          <div className="grid-col-fill">
            <h1>{title}</h1>
            <main>{children}</main>
          </div>
        </div>
      </div>
    </>
  );
}

export default Page;
