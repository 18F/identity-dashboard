import { expect } from "chai";
import { yearMonthDayParse } from "../formats";
import { ProcessedResult } from "../models/daily-registrations-report-data";
import { tabulate } from "./daily-registrations-report";

describe("DailyRegistrationsReport", () => {
  describe("#tabulate", () => {
    it("renders a table", () => {
      const results: ProcessedResult[] = [
        {
          date: yearMonthDayParse("2020-01-01"),
          totalUsers: 5,
          fullyRegisteredUsers: 1,
          totalUsersCumulative: 10,
          fullyRegisteredUsersCumulative: 2,
          deletedUsers: 3,
          deletedUsersCumulative: 5,
        },
        {
          date: yearMonthDayParse("2020-01-02"),
          totalUsers: 6,
          fullyRegisteredUsers: 2,
          totalUsersCumulative: 17,
          fullyRegisteredUsersCumulative: 4,
          deletedUsers: 4,
          deletedUsersCumulative: 9,
        },
      ];

      const table = tabulate(results);

      expect(table).to.deep.equal({
        header: [
          "Date",
          "New Users",
          "New Fully Registered Users",
          "Deleted Users",
          "Cumulative Users",
          "Cumulative Fully Registered Users",
          "Cumulative Deleted Users",
        ],
        body: [
          ["2020-01-02", 6, 2, 4, 17, 4, 9],
          ["2020-01-01", 5, 1, 3, 10, 2, 5],
        ],
      });
    });
  });
});
