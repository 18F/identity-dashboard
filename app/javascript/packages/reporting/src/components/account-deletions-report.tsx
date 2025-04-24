import { useContext, useRef } from "preact/hooks";
import { ascending, flatGroup, mean } from "d3-array";
import { utcWeek, utcMonday } from "d3-time";
import * as Plot from "@observablehq/plot";
import useRegistrationData from "../hooks/use-registration-data";
import useElementWidth from "../hooks/use-element-width";
import { ReportFilterContext } from "../contexts/report-filter-context";
import {
  formatAsDecimalPercent,
  formatAsPercent,
  yearMonthDayFormat,
} from "../formats";
import PlotComponent from "./plot";
import Table, { Td } from "./table";
import type { ProcessedResult } from "../models/daily-registrations-report-data";
import type { TableData } from "./table";

interface ProcessedFormattedData {
  date: Date;
  deletedUsers: number;
  fullyRegisteredUsers: number;
  rate: number;
}

interface PlotOptions {
  data: ProcessedFormattedData[];
  width?: number;
  finish: Date;
}

function plot({ data, width, finish }: PlotOptions): HTMLElement {
  return Plot.plot({
    color: {
      type: "ordinal",
      scheme: "Tableau10",
    },
    marks: [
      Plot.ruleY([0]),
      Plot.line(data, { x: "date", y: "rate" }),
      Plot.ruleY(
        data,
        Plot.binY(
          { y: "mean" },
          {
            strokeDasharray: "3,2",
            thresholds: utcWeek,
            y: "rate",
          }
        )
      ),
      Plot.text(
        data,
        Plot.binY(
          { y: "mean" },
          {
            y: "rate",
            text: (bin: ProcessedFormattedData[]) =>
              formatAsDecimalPercent(mean(bin, (d) => d.rate) || 0),
            x: finish,
            thresholds: utcWeek,
            textAnchor: "end",
            lineAnchor: "bottom",
          }
        )
      ),
    ],
    width,
    y: {
      domain: [0, 0.1],
      tickFormat: formatAsPercent,
    },
  });
}

export function tabulate(results: ProcessedFormattedData[]): TableData {
  return {
    header: ["Week Start", "Deleted Users", "Fully Registered Users", "Deletion Rate"],
    body: results
      .sort(({ date: aDate }, { date: bDate }) => ascending(aDate, bDate))
      .map(({ date, deletedUsers, fullyRegisteredUsers, rate }) => [
        yearMonthDayFormat(date),
        <Td.NumberWithCommas number={deletedUsers} />,
        <Td.NumberWithCommas number={fullyRegisteredUsers} />,
        <Td.NumberAsDecimalPercent number={rate} />,
      ]),
  };
}

export function formatData(data: ProcessedResult[]): ProcessedFormattedData[] {
  return flatGroup(data, (value) => utcMonday(value.date)).flatMap(([week, entries]) => {
    const { deletedUsers, fullyRegisteredUsers } = entries.reduce(
      (result, entry) => ({
        deletedUsers: result.deletedUsers + entry.deletedUsers,
        fullyRegisteredUsers: result.fullyRegisteredUsers + entry.fullyRegisteredUsers,
      }),
      { deletedUsers: 0, fullyRegisteredUsers: 0 }
    );
    const rate = deletedUsers / fullyRegisteredUsers;

    return { date: week, deletedUsers, fullyRegisteredUsers, rate };
  });
}

function AccountDeletionsReport() {
  const { start, finish } = useContext(ReportFilterContext);
  const ref = useRef<HTMLDivElement>(null);
  const data = useRegistrationData({ start, finish });
  const width = useElementWidth(ref);

  const formattedData = formatData(data || []);

  return (
    <div ref={ref}>
      <PlotComponent
        plotter={() => plot({ data: formattedData, width, finish })}
        inputs={[data, width, finish]}
      />
      <Table data={tabulate(formattedData)} />
    </div>
  );
}

export default AccountDeletionsReport;
