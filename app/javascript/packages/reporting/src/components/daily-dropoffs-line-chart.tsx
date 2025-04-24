import { max } from "d3-array";
import { axisLeft, axisBottom } from "d3-axis";
import { scalePoint, scaleLinear } from "d3-scale";
import { VNode } from "preact";
import { useState } from "preact/hooks";
import { line as d3Line } from "d3-shape";
import { formatWithCommas, formatAsPercent } from "../formats";
import {
  DailyDropoffsRow,
  funnelSteps,
  StepCount,
  stepToTitle,
  toStepCounts,
} from "../models/daily-dropoffs-report-data";
import Axis from "./axis";
import { FunnelMode, Scale } from "../contexts/report-filter-context";

function DailyDropoffsLineChart({
  data,
  funnelMode,
  scale,
  color,
  width = 400,
  height = 400,
}: {
  data: DailyDropoffsRow[];
  funnelMode: FunnelMode;
  scale: Scale;
  color: (issuer: string) => string;
  width?: number;
  height?: number;
}): VNode {
  const [highlightedIssuer, setHighlightedIssuer] = useState(undefined as string | undefined);
  const highlightedRow = data.find(({ issuer }) => issuer === highlightedIssuer);

  const margin = {
    top: 30,
    right: 50,
    bottom: 50,
    left: 50,
  };

  const innerWidth = width - margin.left - margin.right;
  const innerHeight = height - margin.top - margin.bottom;

  const steps = funnelSteps(funnelMode);

  const x = scalePoint()
    .domain(steps.map(({ key }) => key))
    .range([0, innerWidth]);

  const maxCount = max(data || [], (d) => d[steps[0].key]) as number;
  const maxY: number = scale === Scale.COUNT ? maxCount : 1;
  const yAccessor: (s: StepCount) => number =
    scale === Scale.COUNT ? ({ count }) => count : ({ percentOfFirst }) => percentOfFirst;

  const y = scaleLinear().domain([0, maxY]).range([innerHeight, 0]);

  // the type annotations for d3.line assume input is [number, number] which is wrong
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const line = (d3Line() as any)
    .x(({ step }: StepCount) => x(step))
    .y((d: StepCount) => y(yAccessor(d))) as (s: StepCount[]) => string;

  return (
    <svg height={height} width={width} onPointerLeave={() => setHighlightedIssuer(undefined)}>
      <Axis
        axis={axisLeft(y).tickFormat(scale === Scale.PERCENT ? formatAsPercent : formatWithCommas)}
        transform={`translate(${margin.left}, ${margin.top})`}
      />
      <Axis
        axis={axisBottom(x).tickFormat(stepToTitle as (s: string) => string)}
        transform={`translate(${margin.left}, ${margin.top + innerHeight})`}
        className="x-axis"
        rotateLabels={width < 700}
      />
      <text
        x={margin.left + innerWidth}
        y={margin.top}
        dy="-10"
        className="title"
        text-anchor="end"
      >
        {highlightedRow?.friendly_name}
      </text>
      <g transform={`translate(${margin.left}, ${margin.top})`}>
        {(data || []).map((row) => (
          <path
            d={line(toStepCounts(row, funnelMode))}
            fill="none"
            stroke={color(row.issuer)}
            stroke-width="1"
            onPointerEnter={() => setHighlightedIssuer(row.issuer)}
          />
        ))}
      </g>
      <g transform={`translate(${margin.left}, ${margin.top})`}>
        {highlightedRow && (
          <g className="dots">
            {toStepCounts(highlightedRow, funnelMode).map((row, idx) => {
              const { step, count, percentOfFirst } = row;
              return (
                <>
                  <circle
                    cx={x(step)}
                    cy={y(yAccessor(row))}
                    r="3"
                    fill={color(highlightedRow.issuer)}
                  />
                  <text x={x(step)} y={y(yAccessor(row))} font-size="12" dx="3" dy="-3">
                    <tspan x={x(step)}>{formatWithCommas(count)}</tspan>
                    {idx > 0 && (
                      <tspan x={x(step)} dy="1.2em">
                        ({formatAsPercent(percentOfFirst)})
                      </tspan>
                    )}
                  </text>
                </>
              );
            })}
          </g>
        )}
      </g>
    </svg>
  );
}

export default DailyDropoffsLineChart;
