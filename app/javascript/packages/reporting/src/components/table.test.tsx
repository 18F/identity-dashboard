import { expect } from "chai";
import { render } from "@testing-library/preact";
import { csvParse } from "d3-dsv";
import Table, { TableData, Td } from "./table";

describe("Table", () => {
  it("wraps header elements in <th> and body elements in <td>", () => {
    const data = {
      header: ["name", "color"],
      body: [
        ["bob", "red"],
        ["alice", "blue"],
      ],
    };

    const { container } = render(<Table data={data} />);
    const thValues = Array.from(container.querySelectorAll("table thead th")).map(
      (th) => th.textContent
    );
    expect(thValues).to.deep.equal(data.header);

    const tdValues = Array.from(container.querySelectorAll("table tbody tr")).map((tr) =>
      Array.from(tr.querySelectorAll("td")).map((td) => td.textContent)
    );
    expect(tdValues).to.deep.equal(data.body);
  });

  it("wraps footer elements in <td>", () => {
    const data = {
      header: ["name", "color"],
      body: [
        ["bob", "red"],
        ["alice", "blue"],
      ],
      footer: ["count", "2"],
    };

    const { container } = render(<Table data={data} />);

    const tdValues = Array.from(container.querySelectorAll("table tfoot tr td")).map(
      (td) => td.textContent
    );
    expect(tdValues).to.deep.equal(data.footer);
  });

  it("formats numbers as aligned right, using the numberFormatter", () => {
    const data = {
      header: ["num"],
      body: [[1000]],
    };

    function numberFormatter(num: number) {
      return `!!${num}!!`;
    }

    const { container } = render(<Table data={data} numberFormatter={numberFormatter} />);
    const td = container.querySelector("table tbody td");
    expect(td?.textContent).to.equal("!!1000!!");
    expect(td?.classList.contains("text-right")).to.eq(true);
    expect(td?.classList.contains("text-tabular")).to.eq(true);
    expect(td?.classList.contains("table-number")).to.eq(true);
  });

  it("passes through <th> in header and <td> in the body", () => {
    const data: TableData = {
      header: [
        <th colSpan={2} data-something="hi">
          header
        </th>,
      ],
      body: [
        [
          <td colSpan={2} data-something="hello">
            cell
          </td>,
        ],
      ],
    };

    const { container } = render(<Table data={data} />);

    const ths = container.querySelectorAll("table thead th");
    expect(ths.length).to.eq(1);
    const th = ths[0];
    expect(th.getAttribute("colspan")).to.eq("2");
    expect(th.getAttribute("data-something")).to.equal("hi");

    const tds = container.querySelectorAll("table tbody td");
    expect(tds.length).to.eq(1);
    const td = tds[0];
    expect(td.getAttribute("colspan")).to.eq("2");
    expect(td.getAttribute("data-something")).to.equal("hello");
  });

  it("passes through custom <Td> components the body", () => {
    const data: TableData = {
      header: [],
      body: [
        [
          <Td.NumberWithCommas number={1000} />
        ]
      ],
    };

    const { container } = render(<Table data={data} />);

    const tds = container.querySelectorAll("table tbody td");
    expect(tds.length).to.eq(1);
    const td = tds[0];
    expect(td.getAttribute("data-csv")).to.equal("1000");
    expect(td.textContent).to.equal("1,000");
  });

  it("includes a link to download as CSV", () => {
    const data: TableData = {
      header: [
        <th colSpan={2} data-csv={["customHeader1", "customHeader2"]}>
          header
        </th>,
        "header2",
      ],
      body: [[<td colSpan={2}>cell</td>, 1]],
    };
    const { container } = render(<Table data={data} />);

    const as = container.querySelectorAll("a[download]");
    expect(as.length).to.eq(1);
    const a = as[0];

    const href = a.getAttribute("href");
    expect(href?.startsWith("data:text/csv;charset=utf-8,")).to.eq(true);

    const parsed = csvParse(decodeURIComponent(href?.split(",")[1] || ""));
    expect(parsed).to.deep.equal([{ customHeader1: "cell", customHeader2: "", header2: "1" }]);
  });
});
