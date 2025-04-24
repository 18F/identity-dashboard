import { expect } from "chai";
import { scaleOrdinal } from "d3-scale";
import { schemeCategory10 } from "d3-scale-chromatic";
import { FunnelMode, TimeBucket } from "../contexts/report-filter-context";
import { DailyDropoffsRow, Step } from "../models/daily-dropoffs-report-data";
import { tabulateAll, tabulateByAgency, tabulateByIssuer } from "./proofing-over-time-report";

describe("ProofingOverTimeReport", () => {
  const date = new Date();
  const rows = [
    {
      issuer: "issuer1",
      friendly_name: "app1",
      agency: "agency1",
      start: date,
      [Step.WELCOME]: 1,
      [Step.AGREEMENT]: 0,
      [Step.VERIFIED]: 1,
    } as DailyDropoffsRow,
    {
      issuer: "issuer1",
      friendly_name: "app1",
      agency: "agency1",
      start: date,
      [Step.WELCOME]: 1,
      [Step.AGREEMENT]: 1,
      [Step.VERIFIED]: 1,
    } as DailyDropoffsRow,
    {
      issuer: "issuer2",
      friendly_name: "app2",
      agency: "agency1",
      start: date,
      [Step.WELCOME]: 1,
      [Step.AGREEMENT]: 0,
      [Step.VERIFIED]: 0,
    } as DailyDropoffsRow,
    {
      issuer: "issuer3",
      friendly_name: "app3",
      agency: "agency2",
      start: date,
      [Step.WELCOME]: 1,
      [Step.AGREEMENT]: 0,
      [Step.VERIFIED]: 0,
    } as DailyDropoffsRow,
  ];

  describe("#tabulateAll", () => {
    it("adds up across all agencies", () => {
      const table = tabulateAll({
        data: rows,
        timeBucket: TimeBucket.WEEK,
        funnelMode: FunnelMode.BLANKET,
      });

      expect(table.body).to.have.lengthOf(1);
    });
  });

  describe("#tabulateByAgency", () => {
    it("groups by agency", () => {
      const table = tabulateByAgency({
        data: rows,
        timeBucket: TimeBucket.WEEK,
        funnelMode: FunnelMode.BLANKET,
        color: scaleOrdinal(schemeCategory10),
      });

      expect(table.body).to.have.lengthOf(2);
    });
  });

  describe("#tabulateByIssuer", () => {
    it("groups by issuer", () => {
      const table = tabulateByIssuer({
        data: rows,
        timeBucket: TimeBucket.WEEK,
        funnelMode: FunnelMode.BLANKET,
        color: scaleOrdinal(schemeCategory10),
      });

      expect(table.body).to.have.lengthOf(3);
    });
  });
});
