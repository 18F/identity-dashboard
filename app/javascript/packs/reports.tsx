import { h, render } from "preact";
import {
  DailyAuthsReport,
  AgenciesContextProvider,
  ReportFilterControls,
  ReportFilterContextProviderProps,
  ReportFilterContextProvider,
  FunnelMode,
  Scale,
} from "@18f/identity-reporting";

const appDiv = document.getElementById('app');
const start = appDiv?.getAttribute('data-start');
const finish = appDiv?.getAttribute('data-finish');
const ialRaw = Number(appDiv?.getAttribute('data-ial'));
const agency = appDiv?.getAttribute('data-agency');
const extraRaw = appDiv?.getAttribute('data-extra');
const byAgencyRaw = appDiv?.getAttribute('data-byAgency');
const funnelModeRaw = appDiv?.getAttribute('data-funnel-mode');
const scaleRaw = appDiv?.getAttribute('data-scale');

const ial = ialRaw === 1 || ialRaw === 2 ? ialRaw : 1; // Ensure ial is 1 or 2, default to 1
const extra = extraRaw === "true" || extraRaw === "1";
const byAgency = byAgencyRaw === "true" || byAgencyRaw === "on";

// Use the FunnelMode and Scale types if available, otherwise fallback to string unions
const funnelMode: FunnelMode = (funnelModeRaw as FunnelMode);
const scale: Scale = (scaleRaw as Scale);

console.log("Ingested from HTML: ", appDiv);

const contextProps: ReportFilterContextProviderProps = {
  start: start ? new Date(start) : new Date(),
  finish: finish ? new Date(finish) : new Date(),
  ial : ial,
  env: 'local',
  funnelMode: funnelMode,
  scale: scale,
  byAgency: byAgency,
  extra: extra,
  timeBucket: undefined,
  cumulative: true,
  agency,
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

function ReportsApp() {
  // Get extra from context or state if you want it to be reactive
  // If you want to use context, use: const { extra } = useContext(ReportFilterContext);
  const extra = contextProps.extra;
  console.log("extra", extra)
  const reportControls: Control[] = [Control.IAL];
  if (contextProps.extra) {
    console.log("extra true")
    reportControls.push(Control.AGENCY, Control.BY_AGENCY);
  }

  console.log("reportControls:", reportControls)

  return (
    <AgenciesContextProvider>
      <ReportFilterContextProvider {...contextProps}>
        <ReportFilterControls controls={reportControls} />
        <DailyAuthsReport />
      </ReportFilterContextProvider>
    </AgenciesContextProvider>
  );
}

render(<ReportsApp />, document.getElementById("app")!);