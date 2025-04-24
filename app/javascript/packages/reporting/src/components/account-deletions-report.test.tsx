import { expect } from "chai";
import { formatData, tabulate } from "./account-deletions-report";
import { yearMonthDayParse } from "../formats";
import type { ProcessedResult } from "../models/daily-registrations-report-data";
import type { TableRow } from "./table";

describe("AccountDeletionsReport", () => {
  describe("#formatData", () => {
    const results: ProcessedResult[] = [
      {
        date: yearMonthDayParse("2023-01-02"),
        fullyRegisteredUsers: 100,
        deletedUsers: 7,
      } as ProcessedResult,
      ...Array.from(
        Array(6),
        (_value, index) =>
          ({
            date: yearMonthDayParse(`2023-01-0${3 + index}`),
            fullyRegisteredUsers: 100,
            deletedUsers: 0,
          } as ProcessedResult)
      ),
      {
        date: yearMonthDayParse("2023-01-09"),
        fullyRegisteredUsers: 1000,
        deletedUsers: 140,
      } as ProcessedResult,
      ...Array.from(
        Array(6),
        (_value, index) =>
          ({
            date: yearMonthDayParse(`2023-01-1${index}`),
            fullyRegisteredUsers: 1000,
            deletedUsers: 0,
          } as ProcessedResult)
      ),
    ];

    it("formats processed results", () => {
      const formattedData = formatData(results);

      expect(formattedData).to.deep.equal([
        {
          date: yearMonthDayParse("2023-01-02"),
          deletedUsers: 7,
          fullyRegisteredUsers: 700,
          rate: 0.01,
        },
        {
          date: yearMonthDayParse("2023-01-09"),
          deletedUsers: 140,
          fullyRegisteredUsers: 7000,
          rate: 0.02,
        },
      ]);
    });
  });

  describe("#tabulate", () => {
    const formattedData = [
      {
        date: yearMonthDayParse("2023-01-02"),
        deletedUsers: 7,
        fullyRegisteredUsers: 700,
        rate: 0.01,
      },
      {
        date: yearMonthDayParse("2023-01-09"),
        deletedUsers: 140,
        fullyRegisteredUsers: 7000,
        rate: 0.02,
      },
    ];

    it("tabulates formatted data", () => {
      const table = tabulate(formattedData);
      const mapRow = (row: TableRow) =>
        row.map((child) => (typeof child === "object" ? child.props : child));

      expect(table.header).to.deep.equal([
        "Week Start",
        "Deleted Users",
        "Fully Registered Users",
        "Deletion Rate",
      ]);
      expect(table.body.map(mapRow)).to.deep.equal([
        [
          "2023-01-02",
          { number: 7 },
          { number: 700 },
          { number: 0.01 },
        ],
        [
          "2023-01-09",
          { number: 140 },
          { number: 7000 },
          { number: 0.02 },
        ],
      ]);
    });
  });
});
