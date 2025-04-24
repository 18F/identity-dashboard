import { ComponentChildren, VNode } from "preact";
import { useRef, useEffect, Inputs } from "preact/hooks";

interface PlotComponentProps {
  inputs: Inputs;
  plotter: () => HTMLElement;
  children?: ComponentChildren;
}

function PlotComponent({ plotter, inputs, children }: PlotComponentProps): VNode {
  const ref = useRef(null as HTMLDivElement | null);

  useEffect(() => {
    if (ref?.current?.children[0]) {
      ref.current.children[0].remove();
    }

    ref?.current?.appendChild(plotter());
  }, inputs);

  return (
    <div className="chart-wrapper" ref={ref}>
      {children}
    </div>
  );
}

export default PlotComponent;
