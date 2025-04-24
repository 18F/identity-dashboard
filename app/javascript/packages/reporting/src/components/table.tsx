import { VNode, render } from "preact";
import { csvFormatValue } from "d3-dsv";
import { formatAsDecimalPercent, formatAsPercent, formatWithCommas } from "../formats";
import Icon from "./icon";

export type TableCell = string | number | VNode<any>;
export type TableRow = TableCell[];

export interface TableData {
  header: TableRow;
  body: TableRow[];
  footer?: TableRow;
}

type NumberFormatter = (n: number) => string;

interface TableProps {
  data: TableData;
  numberFormatter?: NumberFormatter;
  /**
   * Name for the CSV download of this table
   */
  filename?: string;
}

interface NumericTdProps { number: number, style?: string }

export const Td = {
  NumberWithCommas: ({ number, style }: NumericTdProps): VNode => (
    <td
      data-csv={number}
      className="table-number text-tabular text-right"
      style={style}
    >
      {formatWithCommas(number)}
    </td>
  ),
  NumberAsPercent: ({ number, style }: NumericTdProps): VNode => (
    <td
      data-csv={number}
      className="table-number text-tabular text-right"
      style={style}
    >
      {formatAsPercent(number)}
    </td>
  ),
  NumberAsDecimalPercent: ({ number, style }: NumericTdProps): VNode => (
    <td
      data-csv={number}
      className="table-number text-tabular text-right"
      style={style}
    >
      {formatAsDecimalPercent(number)}
    </td>
  )
};

function Row({
  row,
  numberFormatter = String,
}: {
  row: TableRow;
  numberFormatter: NumberFormatter;
}): VNode {
  return (
    <tr>
      {row.map((d) => {
        if (typeof d === "object" && (d.type === "td" || Object.values(Td).includes(d.type as any))) {
          return d;
        }
        if (typeof d === "number") {
          return <td className="table-number text-tabular text-right">{numberFormatter(d)}</td>;
        }
        return <td>{d}</td>;
      })}
    </tr>
  );
}

/**
 * Used in textContent, created once to save some overhead
 */
const doc = document.implementation.createHTMLDocument("");

function textContent(v: VNode): string {
  doc.body.innerHTML = "";
  render(v, doc.body);
  return doc.body.textContent || "";
}

interface CSVProps {
  "data-csv": string[];
  colSpan: number;
}

function toCSVValues(cell: TableCell): string[] {
  if (typeof cell === "object") {
    if ("data-csv" in cell.props) {
      return (cell.props as CSVProps)["data-csv"];
    }

    const text = textContent(cell);
    const colspan = (cell.props as CSVProps).colSpan || 1;

    const empties = Array(colspan - 1).fill("");

    return [text, ...empties];
  }
  return [String(cell)];
}

function toCSV(data: TableData): string {
  const { header, body } = data;

  const rows = [
    header.flatMap((v) => toCSVValues(v)),
    ...body.map((row) => row.flatMap((v) => toCSVValues(v))),
  ];

  return rows.map((row) => row.map((c) => csvFormatValue(c)).join(",")).join("\n");
}

function Table({ data, filename, numberFormatter = String }: TableProps): VNode {
  const { header, body, footer } = data;
  return (
    <>
      <div className="usa-table-container--scrollable">
        <table className="usa-table usa-table--compact">
          <thead>
            <tr>
              {header.map((head) =>
                typeof head === "object" && head.type === "th" ? head : <th>{head}</th>
              )}
            </tr>
          </thead>
          <tbody>
            {body.map((row) => (
              <Row row={row} numberFormatter={numberFormatter} />
            ))}
          </tbody>
          {footer && (
            <tfoot>
              <Row row={footer} numberFormatter={numberFormatter} />
            </tfoot>
          )}
        </table>
      </div>

      <a
        className="usa-button usa-button--outline"
        download={filename || "report.csv"}
        href={`data:text/csv;charset=utf-8,${encodeURIComponent(toCSV(data))}`}
      >
        <Icon icon="file_download" />
        Download as CSV
      </a>
    </>
  );
}

export default Table;
