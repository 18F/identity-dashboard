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

async function loadData(
  start: Date,
  finish: Date,
  env: string,
  fetch = window.fetch
): Promise<ProcessedResult[]> {
  console.log("loadData called with:", { start, finish, env });

  const dates = utcDays(start, utcDay.offset(finish, 1), 1);
  const reports = await Promise.all(
    dates.map(async (date) => {
      const path = reportPath({ reportName: "daily-auths-report", date, env });
      try {
        const response = await fetch(path, { mode: 'no-cors' });
        const text = await response.text();
        console.log(`Raw response body for ${date.toISOString()}:`, text);
        
        if (response.status === 200) {
          return response.json();
        } else {
          console.warn(`Failed to fetch data for ${date.toISOString()}:`, response.status);
          return { results: [] };
        }
      } catch (error) {
        console.error(`Error fetching data for ${date.toISOString()}:`, error);
        return { results: [] };
      }
    })
  );

  return reports.flatMap((r) => process(r));
}

export { ProcessedResult, loadData };
