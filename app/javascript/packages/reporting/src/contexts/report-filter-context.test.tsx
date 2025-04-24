import { expect } from "chai";
import { useContext } from "preact/hooks";
import { render } from "@testing-library/preact";
import { DEFAULT_ENV, DEFAULT_IAL, ReportFilterContext } from "./report-filter-context";

describe("ReportFilterContext", () => {
  function TestComponent() {
    return <>{JSON.stringify(useContext(ReportFilterContext))}</>;
  }

  it("has expected default properties", () => {
    const html = render(<TestComponent />).container.innerHTML;
    const result = JSON.parse(html);

    expect(result.ial).to.eq(DEFAULT_IAL);
    expect(result.env).to.eq(DEFAULT_ENV);
  });
});
