import { Axis as D3Axis } from "d3-axis";
import { NumberValue } from "d3-scale";
import { select } from "d3-selection";
import { VNode } from "preact";
import { useRef, useEffect } from "preact/hooks";

function Axis({
  axis,
  transform,
  rotateLabels,
  className,
}: {
  axis: D3Axis<NumberValue> | D3Axis<string>;
  transform: string;
  rotateLabels?: boolean;
  className?: string;
}): VNode {
  const ref = useRef(null as SVGGElement | null);

  useEffect(() => {
    if (ref.current) {
      select(ref.current).call(axis).classed("rotate-labels", !!rotateLabels);
    }
  }, [axis, rotateLabels]);

  return <g ref={ref} className={className} transform={transform} />;
}

export default Axis;
