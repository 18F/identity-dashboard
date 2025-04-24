import { expect } from "chai";
import fetchMock from "fetch-mock";
import { utcParse } from "d3-time-format";
import {
  DailyDropoffsRow,
  Step,
  aggregate,
  loadData,
  toStepCounts,
  aggregateAll,
} from "./daily-dropoffs-report-data";
import { FunnelMode } from "../contexts/report-filter-context";
import { yearMonthDayFormat } from "../formats";

describe("DailyDropoffsReportData", () => {
  describe("#aggregate", () => {
    it("sums up rows by issuer", () => {
      const date = new Date();

      const rows = [
        {
          issuer: "issuer1",
          friendly_name: "app1",
          agency: "agency1",
          iaa: "iaa123",
          start: date,
          finish: date,
          [Step.WELCOME]: 1,
          [Step.AGREEMENT]: 0,
          [Step.VERIFIED]: 1,
        } as DailyDropoffsRow,
        {
          issuer: "issuer1",
          friendly_name: "app1",
          agency: "agency1",
          iaa: "iaa123",
          start: date,
          finish: date,
          [Step.WELCOME]: 1,
          [Step.AGREEMENT]: 1,
          [Step.VERIFIED]: 1,
        } as DailyDropoffsRow,
        {
          issuer: "issuer2",
          friendly_name: "app2",
          agency: "agency2",
          iaa: "iaa123",
          start: date,
          finish: date,
          [Step.WELCOME]: 1,
          [Step.AGREEMENT]: 0,
          [Step.VERIFIED]: 0,
        } as DailyDropoffsRow,
      ];

      const aggregated = aggregate(rows);
      expect(aggregated).to.deep.equal([
        {
          issuer: "issuer1",
          friendly_name: "app1",
          agency: "agency1",
          iaa: "iaa123",
          start: date,
          finish: date,
          [Step.WELCOME]: 2,
          [Step.AGREEMENT]: 1,
          [Step.CAPTURE_DOCUMENT]: 0,
          [Step.CAP_DOC_SUBMIT]: 0,
          [Step.SSN]: 0,
          [Step.VERIFY_INFO]: 0,
          [Step.VERIFY_SUBMIT]: 0,
          [Step.PHONE]: 0,
          [Step.ENCRYPT]: 0,
          [Step.PERSONAL_KEY]: 0,
          [Step.VERIFIED]: 2,
        },
        {
          issuer: "issuer2",
          friendly_name: "app2",
          agency: "agency2",
          iaa: "iaa123",
          start: date,
          finish: date,
          [Step.WELCOME]: 1,
          [Step.AGREEMENT]: 0,
          [Step.CAPTURE_DOCUMENT]: 0,
          [Step.CAP_DOC_SUBMIT]: 0,
          [Step.SSN]: 0,
          [Step.VERIFY_INFO]: 0,
          [Step.VERIFY_SUBMIT]: 0,
          [Step.PHONE]: 0,
          [Step.ENCRYPT]: 0,
          [Step.PERSONAL_KEY]: 0,
          [Step.VERIFIED]: 0,
        },
      ]);
    });
  });

  describe("#aggregateAll", () => {
    it("sums up rows across issuers", () => {
      const date = new Date();

      const rows = [
        {
          issuer: "issuer1",
          friendly_name: "app1",
          agency: "agency1",
          iaa: "iaa123",
          start: date,
          finish: date,
          [Step.WELCOME]: 1,
          [Step.AGREEMENT]: 0,
          [Step.VERIFIED]: 1,
        } as DailyDropoffsRow,
        {
          issuer: "issuer1",
          friendly_name: "app1",
          agency: "agency1",
          iaa: "iaa123",
          start: date,
          finish: date,
          [Step.WELCOME]: 1,
          [Step.AGREEMENT]: 1,
          [Step.VERIFIED]: 1,
        } as DailyDropoffsRow,
        {
          issuer: "issuer2",
          friendly_name: "app2",
          agency: "agency2",
          iaa: "iaa123",
          start: date,
          finish: date,
          [Step.WELCOME]: 1,
          [Step.AGREEMENT]: 0,
          [Step.VERIFIED]: 0,
        } as DailyDropoffsRow,
      ];

      const aggregated = aggregateAll(rows);
      expect(aggregated).to.deep.equal([
        {
          issuer: "",
          friendly_name: "",
          agency: "(all)",
          iaa: "",
          start: date,
          finish: date,
          [Step.WELCOME]: 3,
          [Step.AGREEMENT]: 1,
          [Step.CAPTURE_DOCUMENT]: 0,
          [Step.CAP_DOC_SUBMIT]: 0,
          [Step.SSN]: 0,
          [Step.VERIFY_INFO]: 0,
          [Step.VERIFY_SUBMIT]: 0,
          [Step.PHONE]: 0,
          [Step.ENCRYPT]: 0,
          [Step.PERSONAL_KEY]: 0,
          [Step.VERIFIED]: 2,
        },
      ]);
    });
  });

  describe("#loadData", () => {
    const yearMonthDayParse = utcParse("%Y-%m-%d") as (s: string) => Date;

    it("concatenates data across separate fetch requests", () => {
      const fetch = fetchMock
        .sandbox()
        .get(
          "/local/daily-dropoffs-report/2021/2021-01-01.daily-dropoffs-report.csv",
          `issuer,friendly_name,iaa,agency,start,finish,welcome,agreement,capture_document,cap_doc_submit,ssn,verify_info,verify_submit,phone,encrypt,personal_key,verified
issuer1,The App,iaa123,The Agency,2021-01-01T00:00:00+00:00,2021-01-01T23:59:59+00:00,3,2,2,2,2,2,2,2,2,2,1`
        )
        .get(
          "/local/daily-dropoffs-report/2021/2021-01-02.daily-dropoffs-report.csv",
          `issuer,friendly_name,iaa,agency,start,finish,welcome,agreement,capture_document,cap_doc_submit,ssn,verify_info,verify_submit,phone,encrypt,personal_key,verified
issuer1,The App,iaa123,The Agency,2021-01-02T00:00:00+00:00,2021-01-02T23:59:59+00:00,2,1,1,1,1,1,1,1,1,1,0`
        )
        .get(
          "/local/daily-dropoffs-report/2021/2021-01-03.daily-dropoffs-report.csv",
          `issuer,friendly_name,iaa,agency,start,finish,welcome,agreement,capture_document,cap_doc_submit,ssn,verify_info,verify_submit,phone,encrypt,personal_key,verified
issuer1,The App,iaa123,The Agency,2021-01-03T00:00:00+00:00,2021-01-03T23:59:59+00:00,2,1,1,1,1,1,1,1,1,1,0`
        );

      return loadData(
        yearMonthDayParse("2021-01-01"),
        yearMonthDayParse("2021-01-03"),
        "local",
        fetch as typeof window.fetch
      ).then((concatenatedRows) => {
        expect(concatenatedRows).to.have.lengthOf(3);

        const [row0, row1, row2] = concatenatedRows;

        expect(row0.issuer).to.equal("issuer1");
        expect(row0.friendly_name).to.equal("The App");
        expect(row0.welcome).to.equal(3);
        expect(row0.verified).to.equal(1);
        expect(yearMonthDayFormat(row0.start)).to.eq("2021-01-01");

        expect(row1.issuer).to.equal("issuer1");
        expect(row1.friendly_name).to.equal("The App");
        expect(row1.welcome).to.equal(2);
        expect(row1.verified).to.equal(0);
        expect(yearMonthDayFormat(row1.start)).to.eq("2021-01-02");

        expect(row2.issuer).to.equal("issuer1");
        expect(row2.friendly_name).to.equal("The App");
        expect(row2.welcome).to.equal(2);
        expect(row2.verified).to.equal(0);
        expect(yearMonthDayFormat(row2.start)).to.eq("2021-01-03");
      });
    });

    it("gracefully handles missing days", () => {
      const fetch = fetchMock
        .sandbox()
        .get(
          "/local/daily-dropoffs-report/2021/2021-01-01.daily-dropoffs-report.csv",
          `issuer,friendly_name,iaa,agency,start,finish,welcome,agreement,capture_document,cap_doc_submit,ssn,verify_info,verify_submit,phone,encrypt,personal_key,verified
issuer1,The App,iaa123,The Agency,2021-01-01T00:00:00+01:00,2021-01-01T23:59:59+01:00,3,2,2,2,2,2,2,2,2,2,1`
        )
        .get("/local/daily-dropoffs-report/2021/2021-01-02.daily-dropoffs-report.csv", 403)
        .get("/local/daily-dropoffs-report/2021/2021-01-03.daily-dropoffs-report.csv", 403);

      return loadData(
        yearMonthDayParse("2021-01-01"),
        yearMonthDayParse("2021-01-03"),
        "local",
        fetch as typeof window.fetch
      ).then((combinedRows) => {
        expect(combinedRows).to.have.lengthOf(1);
      });
    });

    after(() => fetchMock.restore());
  });

  describe("#toStepCounts", () => {
    const row = {
      issuer: "issuer1",
      friendly_name: "app1",
      agency: "agency1",
      iaa: "iaa123",
      start: new Date(),
      finish: new Date(),
      [Step.WELCOME]: 1e10,
      [Step.AGREEMENT]: 1e9,
      [Step.CAPTURE_DOCUMENT]: 1e8,
      [Step.CAP_DOC_SUBMIT]: 1e7,
      [Step.SSN]: 1e6,
      [Step.VERIFY_INFO]: 1e5,
      [Step.VERIFY_SUBMIT]: 1e4,
      [Step.PHONE]: 1000,
      [Step.ENCRYPT]: 100,
      [Step.PERSONAL_KEY]: 10,
      [Step.VERIFIED]: 1,
    };

    it("converts a single row into an array of steps with counts and percents", () => {
      expect(toStepCounts(row, FunnelMode.BLANKET)).to.deep.equal([
        { step: Step.WELCOME, count: 1e10, percentOfFirst: 1, percentOfPrevious: 1 },
        { step: Step.AGREEMENT, count: 1e9, percentOfFirst: 0.1, percentOfPrevious: 0.1 },
        { step: Step.CAPTURE_DOCUMENT, count: 1e8, percentOfFirst: 0.01, percentOfPrevious: 0.1 },
        { step: Step.CAP_DOC_SUBMIT, count: 1e7, percentOfFirst: 0.001, percentOfPrevious: 0.1 },
        { step: Step.SSN, count: 1e6, percentOfFirst: 1e-4, percentOfPrevious: 0.1 },
        { step: Step.VERIFY_INFO, count: 1e5, percentOfFirst: 1e-5, percentOfPrevious: 0.1 },
        { step: Step.VERIFY_SUBMIT, count: 1e4, percentOfFirst: 1e-6, percentOfPrevious: 0.1 },
        { step: Step.PHONE, count: 1000, percentOfFirst: 1e-7, percentOfPrevious: 0.1 },
        { step: Step.ENCRYPT, count: 100, percentOfFirst: 1e-8, percentOfPrevious: 0.1 },
        { step: Step.PERSONAL_KEY, count: 10, percentOfFirst: 1e-9, percentOfPrevious: 0.1 },
        { step: Step.VERIFIED, count: 1, percentOfFirst: 1e-10, percentOfPrevious: 0.1 },
      ]);
    });

    it("starts at the image submit step for ACTUAL mode", () => {
      expect(toStepCounts(row, FunnelMode.ACTUAL)).to.deep.equal([
        { step: Step.CAP_DOC_SUBMIT, count: 1e7, percentOfFirst: 1, percentOfPrevious: 1 },
        { step: Step.SSN, count: 1e6, percentOfFirst: 0.1, percentOfPrevious: 0.1 },
        { step: Step.VERIFY_INFO, count: 1e5, percentOfFirst: 0.01, percentOfPrevious: 0.1 },
        { step: Step.VERIFY_SUBMIT, count: 1e4, percentOfFirst: 0.001, percentOfPrevious: 0.1 },
        { step: Step.PHONE, count: 1000, percentOfFirst: 1e-4, percentOfPrevious: 0.1 },
        { step: Step.ENCRYPT, count: 100, percentOfFirst: 1e-5, percentOfPrevious: 0.1 },
        { step: Step.PERSONAL_KEY, count: 10, percentOfFirst: 1e-6, percentOfPrevious: 0.1 },
        { step: Step.VERIFIED, count: 1, percentOfFirst: 1e-7, percentOfPrevious: 0.1 },
      ]);
    });
  });
});
