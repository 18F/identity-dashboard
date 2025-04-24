import { expect } from "chai";
import { path } from "./api-path";

describe("Report", () => {
  describe("#path", () => {
    it("formats a report as a path", () => {
      const date = new Date("2021-12-01");

      expect(path({ reportName: "some-report", date, env: "local" })).to.equal(
        "/local/some-report/2021/2021-12-01.some-report.json"
      );

      expect(path({ reportName: "some-report", date, env: "prod" })).to.equal(
        "https://public-reporting-data.prod.login.gov/prod/some-report/2021/2021-12-01.some-report.json"
      );
    });
  });
});
