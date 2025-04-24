import { VNode } from "preact";
import { utcParse } from "d3-time-format";
import { utcWeek, utcDay } from "d3-time";
import { AgenciesContextProvider } from "../contexts/agencies-context";
import ReportFilterContextProvider, {
  DEFAULT_IAL,
  DEFAULT_ENV,
  Scale,
  DEFAULT_SCALE,
  DEFAULT_FUNNEL_MODE,
  FunnelMode,
  TimeBucket,
} from "../contexts/report-filter-context";
import ReportFilterControls, { Control } from "../components/report-filter-controls";
import Page from "../components/page";
import ALL_ROUTES from "./all";

const yearMonthDayParse = utcParse("%Y-%m-%d");

export type ReportRoute = (props: ReportRouteProps) => VNode;

interface ReportRouteProps {
  path: keyof typeof ALL_ROUTES;
  start?: string;
  finish?: string;
  ial?: string;
  /**
   * If present, which agency to filter results down to
   * If absent, show all agencies
   */
  agency?: string;
  env?: string;
  funnelMode?: FunnelMode;
  scale?: Scale;
  timeBucket?: TimeBucket;

  /**
   * When "on" the report should show per-agency data
   * When "off" the report should sum up data across all agencies
   */
  byAgency?: "on" | "off";

  /**
   * Whether or not to show extra controls
   */
  extra?: string;

  /**
   * When "on" the report should show cumulative data
   * When "off" it should show daily data
   */
  cumulative?: "on" | "off";
}

function createReportRoute(
  Report: () => VNode,
  {
    controls,
    defaultScale,
    defaultTimeRangeWeekOffset = 0,
  }: {
    controls?: Control[];
    defaultTimeRangeWeekOffset?: number;
    defaultScale?: Scale;
  }
): ReportRoute {
  return ({
    path,
    start: startParam,
    finish: finishParam,
    ial: ialParam,
    agency,
    env: envParam,
    funnelMode: funnelModeParam,
    scale: scaleParam,
    byAgency: byAgencyParam,
    extra: extraParam,
    timeBucket,
    cumulative: cumulativeParam,
  }: ReportRouteProps): VNode => {
    const endOfPreviousWeek = utcDay.offset(utcWeek.floor(new Date()), -1);
    const startOfPreviousWeek = utcWeek.offset(
      utcWeek.floor(new Date(endOfPreviousWeek.valueOf() - 1)),
      defaultTimeRangeWeekOffset
    );

    const start = (startParam && yearMonthDayParse(startParam)) || startOfPreviousWeek;
    const finish = (finishParam && yearMonthDayParse(finishParam)) || endOfPreviousWeek;
    const ial = (parseInt(ialParam || "", 10) || DEFAULT_IAL) as 1 | 2;
    const env = envParam || DEFAULT_ENV;
    const funnelMode = funnelModeParam || DEFAULT_FUNNEL_MODE;
    const scale = scaleParam || defaultScale || DEFAULT_SCALE;
    const extra = extraParam === "true";
    const byAgency = byAgencyParam ? byAgencyParam === "on" : extra;
    const cumulative = cumulativeParam ? cumulativeParam === "on" : true;

    const reportControls = controls || [];
    if (extra) {
      reportControls.push(Control.AGENCY);
      reportControls.push(Control.BY_AGENCY);
    }

    const title = ALL_ROUTES[path];

    return (
      <Page path={path} title={title}>
        <AgenciesContextProvider>
          <ReportFilterContextProvider
            start={start}
            finish={finish}
            ial={ial}
            agency={agency}
            env={env}
            funnelMode={funnelMode}
            scale={scale}
            byAgency={byAgency}
            extra={extra}
            timeBucket={timeBucket}
            cumulative={cumulative}
          >
            <ReportFilterControls controls={reportControls} />
            <Report />
          </ReportFilterContextProvider>
        </AgenciesContextProvider>
      </Page>
    );
  };
}

export default createReportRoute;
