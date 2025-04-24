import { utcDays, utcDay } from "d3-time";
import { path as reportPath } from "./api-path";

interface Result {
  count: number;

  ial: 1 | 2;

  issuer: string;

  /**
   * This is always present but we don't use it, so easier to mark as optional
   */
  iaa?: string;

  // eslint-disable-next-line camelcase
  friendly_name: string;

  agency: string;
}

interface DailyAuthsReportData {
  results: Result[];

  /**
   * ISO8601 string
   */
  start: string;

  /**
   * ISO8601 string
   */
  finish: string;
}

interface ProcessedResult extends Result {
  date: Date;
}

function process(report: DailyAuthsReportData): ProcessedResult[] {
  const date = new Date(report.start);
  return report.results.map((r) => ({ ...r, date, agency: r.agency || "(No Agency)" }));
}

function loadData(
  start: Date,
  finish: Date,
  env: string,
  fetch = window.fetch
): Promise<ProcessedResult[]> {
  return Promise.all(
    utcDays(start, utcDay.offset(finish, 1), 1).map((date) => {
      const path = reportPath({ reportName: "daily-auths-report", date, env });
      return fetch(path).then((response) =>
        response.status === 200 ? response.json() : { results: [] }
      );
    })
  ).then((reports) => reports.flatMap((r) => process(r)));
}

export { ProcessedResult, loadData };
