import { ComponentChildren, VNode } from "preact";
import useInstanceId from "../hooks/use-instance-id";

interface AccordionProps {
  title: string | VNode;
  children?: ComponentChildren;
}

function Accordion({ title, children }: AccordionProps): VNode {
  const id = useInstanceId();

  return (
    <div className="usa-accordion usa-accordion--bordered margin-top-2 margin-bottom-2">
      <h3 className="usa-accordion__heading">
        <button
          className="usa-accordion__button"
          aria-controls={id}
          aria-expanded="false"
          type="button"
        >
          {title}
        </button>
      </h3>
      <div className="usa-prose usa-accordion__content" id={id} hidden>
        {children}
      </div>
    </div>
  );
}

export default Accordion;
