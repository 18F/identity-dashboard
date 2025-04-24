import { VNode } from "preact";
import { scaleLinear } from "d3-scale";
import { ascending } from "d3-array";
import Markdown from "preact-markdown";
import { FunnelMode } from "../contexts/report-filter-context";
import { TableData, Td } from "./table";
import { DailyDropoffsRow, funnelSteps, toStepCounts } from "../models/daily-dropoffs-report-data";
import { formatWithCommas } from "../formats";

function tabulate({
  rows: unsortedRows,
  funnelMode,
  issuerColor,
}: {
  rows: DailyDropoffsRow[];
  funnelMode: FunnelMode;
  issuerColor: (issuer: string) => string;
}): TableData {
  const rows = unsortedRows.sort(
    (
      { agency: agencyA, friendly_name: friendlyNameA },
      { agency: agencyB, friendly_name: friendlyNameB }
    ) => ascending(agencyA, agencyB) || ascending(friendlyNameA, friendlyNameB)
  );

  const header = [
    "Agency",
    <span data-csv={["Issuer", "Friendly Name"]}>App</span>,
    ...funnelSteps(funnelMode).map(({ title }, idx) => (
      <th colSpan={idx === 0 ? 1 : 2}>{title}</th>
    )),
  ];

  const color = scaleLinear()
    .domain([1, 0])
    .range([
      // scaleLinear can interpolate string colors, but the 3rd party type annotations don't know that yet
      "steelblue" as unknown as number,
      "white" as unknown as number,
    ]);

  const totals = funnelSteps(funnelMode).map(() => 0);

  const body = rows.map((row) => {
    const { agency, issuer, friendly_name: friendlyName } = row;

    return [
      agency,
      <span title={issuer} data-csv={[issuer, friendlyName]}>
        <span style={`color: ${issuerColor(issuer)}`}>⬤ </span>
        {friendlyName}
      </span>,
      ...toStepCounts(row, funnelMode).flatMap(({ count, percentOfFirst }, idx) => {
        const backgroundColor = `background-color: ${color(percentOfFirst)};`;
        const cells = [
          <Td.NumberWithCommas style={backgroundColor} number={count} />
        ];

        if (idx > 0) {
          cells.push(
            <Td.NumberAsPercent style={backgroundColor} number={percentOfFirst} />
          );
        }

        totals[idx] += count;

        return cells;
      }),
    ];
  });

  return {
    header,
    body,
    footer: [
      "Total",
      "",
      ...totals
        .flatMap((total, idx) =>
          idx > 0 ? [formatWithCommas(total), ""] : formatWithCommas(total)
        )
        .map((d) => <td className="table-number text-tabular text-right">{d}</td>),
    ],
  };
}

function DailyDropffsReport(): VNode {
  return (
    <div className="padding-bottom-5">
      <Markdown
        markdown={`
## This Report is Unavailable Right Now

We're investigating inconsistencies in the underlying data.
`}
      />
    </div>
  );
}

export default DailyDropffsReport;
export { tabulate };
