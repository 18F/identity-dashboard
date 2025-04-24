import sinon from "sinon";
import { render } from "@testing-library/preact";
import { yearMonthDayParse } from "../formats";
import useRegistrationData from "./use-registration-data";
import type { RegistrationDataOptions } from "./use-registration-data";

describe("useRegistrationData", () => {
  function TestComponent({ start, finish, loadData }: RegistrationDataOptions) {
    return <>{JSON.stringify(useRegistrationData({ start, finish, loadData }))}</>;
  }

  it("loads data for report by given finish date", async () => {
    const finish = yearMonthDayParse("2023-01-02");
    const data = [
      {
        date: yearMonthDayParse("2023-01-02"),
        fullyRegisteredUsers: 100,
        deletedUsers: 7,
      },
    ];
    const loadData = sinon.stub().withArgs(finish, sinon.match.string).resolves(data);
    const { findByText } = render(<TestComponent finish={finish} loadData={loadData} />);

    await findByText(JSON.stringify(data));
  });

  context("with start date threshold", () => {
    it("loads data for report by given finish date, filtered from start date", async () => {
      const start = yearMonthDayParse("2023-01-02");
      const finish = yearMonthDayParse("2023-01-02");
      const data = [
        {
          date: yearMonthDayParse("2023-01-01"),
          fullyRegisteredUsers: 100,
          deletedUsers: 7,
        },
        {
          date: yearMonthDayParse("2023-01-02"),
          fullyRegisteredUsers: 100,
          deletedUsers: 7,
        },
      ];
      const loadData = sinon.stub().withArgs(finish, sinon.match.string).resolves(data);
      const { findByText } = render(
        <TestComponent start={start} finish={finish} loadData={loadData} />
      );

      await findByText(JSON.stringify(data.slice(1)));
    });
  });
});
