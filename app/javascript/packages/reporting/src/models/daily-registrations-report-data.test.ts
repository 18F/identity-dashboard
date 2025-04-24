import { expect } from "chai";
import fetchMock from "fetch-mock";
import { yearMonthDayParse } from "../formats";
import { DataType, loadData, toRenderableData } from "./daily-registrations-report-data";

describe("DailyRegistrationsReportData", () => {
  describe("#loadData", () => {
    it("loads data and processes it", () => {
      const fetch = fetchMock
        .sandbox()
        .get("/local/daily-registrations-report/2021/2021-01-02.daily-registrations-report.json", {
          finish: "2020-01-03",
          results: [
            { date: "2020-01-01", total_users: 2, fully_registered_users: 1, deleted_users: 1 },
            { date: "2020-01-02", total_users: 20, fully_registered_users: 10, deleted_users: 1 },
          ],
        });

      return loadData(yearMonthDayParse("2021-01-02"), "local", fetch as typeof window.fetch).then(
        (processed) => {
          expect(processed).to.have.lengthOf(2);
          expect(processed).to.deep.equal([
            {
              date: yearMonthDayParse("2020-01-01"),
              totalUsers: 2,
              fullyRegisteredUsers: 1,
              totalUsersCumulative: 2,
              fullyRegisteredUsersCumulative: 1,
              deletedUsers: 1,
              deletedUsersCumulative: 1,
            },
            {
              date: yearMonthDayParse("2020-01-02"),
              totalUsers: 20,
              fullyRegisteredUsers: 10,
              totalUsersCumulative: 22,
              fullyRegisteredUsersCumulative: 11,
              deletedUsers: 1,
              deletedUsersCumulative: 2,
            },
          ]);
        }
      );
    });
  });

  describe("toRenderableData", () => {
    it("breaks into elements with value and type", () => {
      const renderable = toRenderableData([
        {
          date: yearMonthDayParse("2020-01-01"),
          totalUsers: 1,
          fullyRegisteredUsers: 2,
          totalUsersCumulative: 3,
          fullyRegisteredUsersCumulative: 4,
          deletedUsers: 5,
          deletedUsersCumulative: 6,
        },
      ]);

      expect(renderable).to.have.deep.members([
        {
          date: yearMonthDayParse("2020-01-01"),
          type: DataType.TOTAL_USERS,
          value: 1,
        },
        {
          date: yearMonthDayParse("2020-01-01"),
          type: DataType.FULLY_REGISTERED_USERS,
          value: 2,
        },
        {
          date: yearMonthDayParse("2020-01-01"),
          type: DataType.TOTAL_USERS_CUMULATIVE,
          value: 3,
        },
        {
          date: yearMonthDayParse("2020-01-01"),
          type: DataType.FULLY_REGISTERED_USERS_CUMULATIVE,
          value: 4,
        },
        {
          date: yearMonthDayParse("2020-01-01"),
          type: DataType.DELETED_USERS,
          value: 5,
        },
        {
          date: yearMonthDayParse("2020-01-01"),
          type: DataType.DELETED_USERS_CUMULATIVE,
          value: 6,
        },
      ]);
    });
  });
});
