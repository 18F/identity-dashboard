import { h, render } from "preact";
import { DailyAuthsReport, AgenciesContextProvider, ReportFilterControls, ReportFilterContextProvider } from "@18f/identity-reporting";

const appDiv = document.getElementById('app');
const start = appDiv?.getAttribute('data-start');
const finish = appDiv?.getAttribute('data-finish');
const ialRaw = appDiv?.getAttribute('data-ial');
const agency = appDiv?.getAttribute('data-agency');
const ial = ialRaw === "1" || ialRaw === "2" ? Number(ialRaw) : 1; // Ensure ial is 1 or 2, default to 1

console.log("Ingested from HTML: ", appDiv)
// Set your desired default filter values here
const contextProps = {
  start: new Date(start),
  finish: new Date(finish),
  ial: ial,
  env: 'local',
  funnelMode: 'blanket',
  scale: 'count',
  byAgency: false,
  extra: false,
  timeBucket: undefined,
  cumulative: true,
  agency: agency,
};

console.log("contextProps: ", contextProps)


enum Control {
  IAL = "ial",
  FUNNEL_MODE = "funnel_mode",
  SCALE = "scale",
  AGENCY = "agency",
  BY_AGENCY = "by_agency",
  TIME_BUCKET = "time_bucket",
  CUMULATIVE = "cumulative",
}

// Build the controls array based on contextProps.extra
const reportControls: Control[] = [];
reportControls.push(Control.IAL)
if (contextProps.extra) {
  reportControls.push(Control.AGENCY, Control.BY_AGENCY);
}

render(
  <AgenciesContextProvider>
    <ReportFilterContextProvider {...contextProps}>
      <ReportFilterControls controls={reportControls} />
      <DailyAuthsReport />
    </ReportFilterContextProvider>
  </AgenciesContextProvider>,
    document.getElementById("app")!
);